# typed: strict
# frozen_string_literal: true

require "vips"
require "numo/narray"

module NudeNet
  # Handles image preprocessing for the ONNX model
  class ImagePreprocessor
    extend T::Sig

    sig { params(image: T.any(String, Vips::Image), mode: Mode).void }
    def initialize(image, mode: :slow)
      @image = T.let(load_image(image), Vips::Image)
      @mode = T.let(mode, Mode)
    end

    sig { params(binary_data: String, mode: Mode).returns(ImagePreprocessor) }
    def self.new_from_binary(binary_data, mode: :slow)
      # Create Vips image from binary data
      image = Vips::Image.new_from_buffer(binary_data, "")
      preprocessor = allocate
      preprocessor.instance_variable_set(:@image, image)
      preprocessor.instance_variable_set(:@mode, mode)
      preprocessor
    end

    sig { returns([Numo::SFloat, Float]) }
    def preprocess
      # 1. Resize with aspect ratio preservation
      resized, scale = resize_image

      # 2. Convert to RGB array in NCHW format (channels first) for YOLOv8
      rgb_nchw = to_rgb_nchw(resized)

      # 3. Apply YOLOv8 normalization (divide by 255)
      preprocessed = rgb_nchw / 255.0

      [preprocessed, scale]
    end

    private

    sig { params(image: T.any(String, Vips::Image)).returns(Vips::Image) }
    def load_image(image)
      case image
      when String
        Vips::Image.new_from_file(image, access: :sequential)
      else
        # when Vips::Image
        image
      end
    end

    sig { returns([Vips::Image, Float]) }
    def resize_image
      min_side, max_side = @mode.to_sym == :fast ? [320, 320] : [800, 1333]

      width = @image.width
      height = @image.height

      smallest_side = [width, height].min
      scale = min_side.to_f / smallest_side

      largest_side = [width, height].max
      scale = [scale, max_side.to_f / largest_side].min if largest_side * scale > max_side

      # Vips resize: scale is the resize factor
      resized = @image.resize(scale, kernel: :linear)

      [resized, scale]
    end

    sig { params(img: Vips::Image).returns(Numo::SFloat) }
    def to_rgb_nchw(img)
      height = img.height
      width = img.width

      # Get raw RGB memory buffer (very fast!)
      memory_buffer = img.write_to_memory

      # Convert binary buffer to Numo array
      # Vips exports as RGB in uint8 format [H, W, C]
      rgb_hwc = Numo::UInt8.from_binary(memory_buffer)
        .reshape(height, width, 3)
        .cast_to(Numo::SFloat)

      # Convert from HWC (height, width, channels) to CHW (channels, height, width)
      # This is the NCHW format that YOLOv8 expects
      rgb_chw = Numo::SFloat.zeros(3, height, width)
      rgb_chw[0, true, true] = rgb_hwc[true, true, 0]  # R channel
      rgb_chw[1, true, true] = rgb_hwc[true, true, 1]  # G channel
      rgb_chw[2, true, true] = rgb_hwc[true, true, 2]  # B channel

      rgb_chw
    end
  end
end
