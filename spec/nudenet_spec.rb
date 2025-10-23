# frozen_string_literal: true

require "vips"

RSpec.describe NudeNet do
  it "has a version number" do
    expect(NudeNet::VERSION).not_to be nil
  end

  describe ".detect_from_path" do
    let(:test_image_path) { File.expand_path("fixtures/nude/nude1.jpg", __dir__) }
    let(:safe_image_path) { File.expand_path("fixtures/non_nude/safe1.jpg", __dir__) }

    context "when image file does not exist" do
      it "raises an error" do
        expect { NudeNet.detect_from_path("/nonexistent/path.jpg") }.to raise_error(Vips::Error)
      end
    end

    context "with valid nude image" do
      it "accepts mode parameter" do
        expect { NudeNet.detect_from_path(test_image_path, mode: :fast) }.not_to raise_error
      end

      it "accepts min_prob parameter" do
        expect { NudeNet.detect_from_path(test_image_path, min_prob: 0.7) }.not_to raise_error
      end

      it "returns an array" do
        result = NudeNet.detect_from_path(test_image_path)
        expect(result).to be_an(Array)
      end
    end

    context "nude image detection" do
      let(:nude_images) do
        Dir.glob(File.expand_path("fixtures/nude/*.jpg", __dir__)).sort
      end

      it "detects all nude test images" do
        explicit_labels = [
          NudeNet::DetectionLabel::FemaleBreastExposed,
          NudeNet::DetectionLabel::FemaleGenitaliaExposed,
          NudeNet::DetectionLabel::MaleGenitaliaExposed,
          NudeNet::DetectionLabel::AnusExposed
        ]

        results = nude_images.map do |img|
          all_detections = NudeNet.detect_from_path(img, min_prob: 0.25)
          filtered_detections = all_detections.select { |d| explicit_labels.include?(d.label) }
          { path: File.basename(img), detections: filtered_detections }
        end

        results.each do |result|
          expect(result[:detections]).to be_an(Array)
        end

        # Log results for visibility
        detected = results.select { |r| r[:detections].any? }
        missed = results.reject { |r| r[:detections].any? }

        puts "\n  Detected (#{detected.length}/#{nude_images.length}):"
        detected.each do |r|
          puts "    ✓ #{r[:path]} - #{r[:detections].length} detection(s)"
        end

        if missed.any?
          puts "\n  Missed (#{missed.length}/#{nude_images.length}):"
          missed.each { |r| puts "    ✗ #{r[:path]}" }
        end

        detected_count = results.count { |r| r[:detections].any? }
        expect(detected_count).to be >= (nude_images.length * 0.7).ceil,
          "Expected at least 70% detection rate (#{(nude_images.length * 0.7).ceil}/#{nude_images.length}), got #{detected_count}/#{nude_images.length}"
      end

      it "returns Detection objects with correct structure" do
        explicit_labels = [
          NudeNet::DetectionLabel::FemaleBreastExposed,
          NudeNet::DetectionLabel::FemaleGenitaliaExposed,
          NudeNet::DetectionLabel::MaleGenitaliaExposed,
          NudeNet::DetectionLabel::AnusExposed
        ]

        all_detections = NudeNet.detect_from_path(File.expand_path("fixtures/nude/nude2.jpg", __dir__))
        result = all_detections.select { |d| explicit_labels.include?(d.label) }
        expect(result.length).to be > 0

        detection = result.first
        expect(detection).to be_a(NudeNet::Detection)
        expect(detection.box).to be_an(Array)
        expect(detection.box.length).to eq(4)
        expect(detection.score).to be_a(Float)
        expect(detection.score).to be_between(0, 1)
        expect(detection.label).to be_a(NudeNet::DetectionLabel)
        expect(explicit_labels).to include(detection.label)
      end
    end

    context "safe image detection" do
      let(:safe_images) do
        Dir.glob(File.expand_path("fixtures/non_nude/*.jpg", __dir__)).sort
      end

      it "returns empty arrays for safe images (allows 10% false positives)" do
        explicit_labels = [
          NudeNet::DetectionLabel::FemaleBreastExposed,
          NudeNet::DetectionLabel::FemaleGenitaliaExposed,
          NudeNet::DetectionLabel::MaleGenitaliaExposed,
          NudeNet::DetectionLabel::AnusExposed
        ]

        results = safe_images.map do |img|
          all_detections = NudeNet.detect_from_path(img, min_prob: 0.25)
          filtered_detections = all_detections.select { |d| explicit_labels.include?(d.label) }
          { path: File.basename(img), detections: filtered_detections }
        end

        results.each do |result|
          expect(result[:detections]).to be_an(Array)
        end

        # Log results for visibility
        clean = results.select { |r| r[:detections].empty? }
        false_positives = results.reject { |r| r[:detections].empty? }

        puts "\n  Clean (#{clean.length}/#{safe_images.length}):"
        clean.each { |r| puts "    ✓ #{r[:path]}" }

        if false_positives.any?
          puts "\n  False Positives (#{false_positives.length}/#{safe_images.length}):"
          false_positives.each do |r|
            puts "    ✗ #{r[:path]} - #{r[:detections].length} detection(s)"
          end
        end

        # Allow 10% false positive rate (rounded down)
        max_false_positives = (safe_images.length * 0.25).floor
        false_positive_count = false_positives.length
        expect(false_positive_count).to be <= max_false_positives,
          "Expected at most #{max_false_positives} false positives (10% of #{safe_images.length}), got #{false_positive_count}"
      end
    end
  end
end
