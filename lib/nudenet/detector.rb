# typed: strict
# frozen_string_literal: true

require "onnxruntime"
require "numo/narray"

module NudeNet
  # Thread-safe ONNX model detector
  class Detector
    extend T::Sig

    # Mutex for thread-safe initialization
    @mutex = T.let(Mutex.new, Mutex)

    # Cached class names (loaded once)
    @classes = T.let(nil, T.nilable(T::Array[String]))
    @classes_mutex = T.let(Mutex.new, Mutex)

    sig do
      params(
        image_path: String,
        mode: Mode,
        min_prob: T.nilable(Float),
        debug_logs_enabled: T::Boolean
      ).returns(T::Array[Detection])
    end
    def self.detect_from_path(image_path, mode: :fast, min_prob: nil, debug_logs_enabled: false)
      # Get or create thread-local session
      session = thread_session

      # Set default min_prob
      min_prob ||= 0.25

      # Preprocess image from path
      preprocess_start = Time.now
      preprocessor = ImagePreprocessor.new(image_path, mode: mode)
      image_data, scale = preprocessor.preprocess
      preprocess_time = ((Time.now - preprocess_start) * 1000).round(1)
      puts "[NudeNet] Preprocessing: #{preprocess_time}ms" if debug_logs_enabled

      # Run inference
      inference_start = Time.now
      result = run_inference(session, image_data, scale, min_prob)
      inference_time = ((Time.now - inference_start) * 1000).round(1)
      puts "[NudeNet] Inference: #{inference_time}ms" if debug_logs_enabled

      result
    end

    sig do
      params(
        image_binary: String,
        mode: Mode,
        min_prob: T.nilable(Float),
        debug_logs_enabled: T::Boolean
      ).returns(T::Array[Detection])
    end
    def self.detect_from_binary(image_binary, mode: :fast, min_prob: nil, debug_logs_enabled: false)
      # Get or create thread-local session
      session = thread_session

      # Set default min_prob
      min_prob ||= 0.25

      # Preprocess image from binary data
      preprocess_start = Time.now
      preprocessor = ImagePreprocessor.new_from_binary(image_binary, mode: mode)
      image_data, scale = preprocessor.preprocess
      preprocess_time = ((Time.now - preprocess_start) * 1000).round(1)
      puts "[NudeNet] Preprocessing: #{preprocess_time}ms" if debug_logs_enabled

      # Run inference
      inference_start = Time.now
      result = run_inference(session, image_data, scale, min_prob)
      inference_time = ((Time.now - inference_start) * 1000).round(1)
      puts "[NudeNet] Inference: #{inference_time}ms" if debug_logs_enabled

      result
    end

    sig { returns(OnnxRuntime::InferenceSession) }
    private_class_method def self.thread_session
      # Use Thread.current to store session and input name per thread
      Thread.current[:nudenet_session] ||= begin
        session = create_session
        # Cache the input name on the thread
        first_input = T.must(session.inputs[0])
        Thread.current[:nudenet_input_name] = first_input[:name]
        session
      end
    end

    sig { returns(String) }
    private_class_method def self.thread_input_name
      # Get cached input name for this thread's session
      T.cast(Thread.current[:nudenet_input_name], String)
    end

    sig { returns(OnnxRuntime::InferenceSession) }
    private_class_method def self.create_session
      model_path = File.expand_path("../../../models/detector.onnx", __FILE__)

      unless File.exist?(model_path)
        raise "Model file not found at #{model_path}"
      end

      OnnxRuntime::InferenceSession.new(
        model_path,
        providers: ["CPUExecutionProvider"]
      )
    end

    sig { returns(T::Array[String]) }
    private_class_method def self.load_classes
      # Return cached classes if available
      cached = @classes
      return cached if cached

      # Thread-safe initialization
      @classes_mutex.synchronize do
        # Double-check locking pattern - Sorbet can't track this flow
        current = T.unsafe(@classes)
        return current if current

        classes_path = File.expand_path("../../../models/classes", __FILE__)

        unless File.exist?(classes_path)
          raise "Classes file not found at #{classes_path}"
        end

        @classes = File.readlines(classes_path).map(&:strip).reject(&:empty?)
      end

      T.must(@classes)
    end

    sig do
      params(
        session: OnnxRuntime::InferenceSession,
        image: Numo::SFloat,
        scale: Float,
        min_prob: Float
      ).returns(T::Array[Detection])
    end
    private_class_method def self.run_inference(session, image, scale, min_prob)
      # Add batch dimension using reshape (faster than zeros + copy)
      shape = image.shape
      input_data = image.reshape(1, T.must(shape[0]), T.must(shape[1]), T.must(shape[2]))

      # Get cached input name
      input_name = thread_input_name

      # Run inference
      outputs = session.run(nil, { input_name => input_data })

      # Parse YOLOv8 output format
      # Output[0]: shape [batch, 22, 2100]
      #   - 22 features = 4 (bbox: x, y, w, h) + 18 (class scores)
      #   - 2100 = total anchor points across all detection heads
      output_array = Numo::SFloat.cast(outputs[0])

      # Load class names
      classes = load_classes

      # Process YOLOv8 detections
      process_yolov8_detections(output_array, classes, scale, min_prob)
    end

    sig do
      params(
        output: Numo::SFloat,
        classes: T::Array[String],
        scale: Float,
        min_prob: Float
      ).returns(T::Array[Detection])
    end
    private_class_method def self.process_yolov8_detections(output, classes, scale, min_prob)
      detections = []

      # Output shape: [1, 22, 2100]
      # Transpose to [1, 2100, 22] for easier processing
      output_t = output.transpose(0, 2, 1)

      # Get first batch: [2100, 22]
      batch_output = output_t[0, true, true]

      # Process each detection
      (0...batch_output.shape[0]).each do |i|
        # First 4 values are bbox: [x_center, y_center, width, height]
        x_center = batch_output[i, 0]
        y_center = batch_output[i, 1]
        width = batch_output[i, 2]
        height = batch_output[i, 3]

        # Next 18 values are class scores
        class_scores = batch_output[i, 4..-1]

        # Find class with highest score
        max_score = class_scores.max
        next if max_score < min_prob

        max_class_idx = class_scores.to_a.index(max_score)
        next if max_class_idx.nil? || max_class_idx >= classes.length

        label_string = classes[max_class_idx]

        # Convert string to enum
        label = DetectionLabel.deserialize(label_string)

        # Convert from center format to corner format [x1, y1, x2, y2]
        # and scale back to original image size
        x1 = ((x_center - width / 2) / scale).round.to_i
        y1 = ((y_center - height / 2) / scale).round.to_i
        x2 = ((x_center + width / 2) / scale).round.to_i
        y2 = ((y_center + height / 2) / scale).round.to_i

        detections << Detection.new(
          box: [x1, y1, x2, y2],
          score: max_score.to_f,
          label: label
        )
      end

      # Apply NMS (Non-Maximum Suppression) to remove overlapping boxes
      apply_nms(detections, iou_threshold: 0.45)
    end

    # Non-Maximum Suppression to filter overlapping boxes
    sig { params(detections: T::Array[Detection], iou_threshold: Float).returns(T::Array[Detection]) }
    private_class_method def self.apply_nms(detections, iou_threshold:)
      return detections if detections.empty?

      # Sort by score descending
      sorted = detections.sort_by { |d| -d.score }
      keep = []

      while sorted.any?
        # Keep the best one
        best = T.must(sorted.shift)
        keep << best

        # Remove boxes that overlap too much with the best one
        sorted.reject! do |det|
          # Only compare same class
          next false unless det.label == best.label

          iou = calculate_iou(best.box, det.box)
          iou > iou_threshold
        end
      end

      keep
    end

    # Calculate Intersection over Union (IoU) between two boxes
    sig { params(box1: T::Array[Integer], box2: T::Array[Integer]).returns(Float) }
    private_class_method def self.calculate_iou(box1, box2)
      x1 = T.must([box1[0], box2[0]].max)
      y1 = T.must([box1[1], box2[1]].max)
      x2 = T.must([box1[2], box2[2]].min)
      y2 = T.must([box1[3], box2[3]].min)

      # Calculate intersection area
      intersection_width = [0, x2 - x1].max
      intersection_height = [0, y2 - y1].max
      intersection_area = intersection_width * intersection_height

      # Calculate union area
      box1_x1 = T.must(box1[0])
      box1_y1 = T.must(box1[1])
      box1_x2 = T.must(box1[2])
      box1_y2 = T.must(box1[3])
      box2_x1 = T.must(box2[0])
      box2_y1 = T.must(box2[1])
      box2_x2 = T.must(box2[2])
      box2_y2 = T.must(box2[3])

      box1_area = (box1_x2 - box1_x1) * (box1_y2 - box1_y1)
      box2_area = (box2_x2 - box2_x1) * (box2_y2 - box2_y1)
      union_area = box1_area + box2_area - intersection_area

      return 0.0 if union_area.zero?

      intersection_area.to_f / union_area.to_f
    end
  end
end
