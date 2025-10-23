# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require "vips"
require "onnxruntime"
require "numo/narray"

require_relative "nudenet/version"
require_relative "nudenet/types"
require_relative "nudenet/detection"
require_relative "nudenet/image_preprocessor"
require_relative "nudenet/detector"

# Main module for NudeNet Ruby implementation
module NudeNet
  extend T::Sig

  # Detect nudity in an image from a file path or URI
  #
  # @param image_uri [String] Path to image file (local path or file:// URI)
  # @param mode [Symbol, String] Detection mode - :slow or :fast
  # @param min_prob [Float, nil] Minimum confidence threshold (default: 0.25)
  # @param debug_logs_enabled [Boolean] Enable timing logs
  # @return [Array<Detection>] Array of detection results
  #
  # @example Basic usage
  #   results = NudeNet.detect_from_path('/path/to/image.jpg')
  #   results.each do |detection|
  #     puts "Found #{detection.label} with confidence #{detection.score}"
  #   end
  #
  # @example Fast mode
  #   results = NudeNet.detect_from_path('/path/to/image.jpg', mode: :fast)
  #
  # @example Custom threshold
  #   results = NudeNet.detect_from_path('/path/to/image.jpg', min_prob: 0.7)
  #
  sig do
    params(
      image_uri: String,
      mode: Mode,
      min_prob: T.nilable(Float),
      debug_logs_enabled: T::Boolean
    ).returns(T::Array[Detection])
  end
  def self.detect_from_path(image_uri, mode: :fast, min_prob: nil, debug_logs_enabled: false)
    Detector.detect_from_path(image_uri, mode: mode, min_prob: min_prob, debug_logs_enabled: debug_logs_enabled)
  end

  # Detect nudity in an image from binary data
  #
  # @param image_data [String] Binary image data (JPEG, PNG, etc.)
  # @param mode [Symbol, String] Detection mode - :slow or :fast
  # @param min_prob [Float, nil] Minimum confidence threshold (default: 0.25)
  # @param debug_logs_enabled [Boolean] Enable timing logs
  # @return [Array<Detection>] Array of detection results
  #
  # @example From URL
  #   require 'open-uri'
  #   image_data = URI.open('https://example.com/image.jpg').read
  #   results = NudeNet.detect_image_data(image_data)
  #
  # @example From file
  #   image_data = File.binread('/path/to/image.jpg')
  #   results = NudeNet.detect_image_data(image_data)
  #
  sig do
    params(
      image_data: String,
      mode: Mode,
      min_prob: T.nilable(Float),
      debug_logs_enabled: T::Boolean
    ).returns(T::Array[Detection])
  end
  def self.detect_image_data(image_data, mode: :fast, min_prob: nil, debug_logs_enabled: false)
    Detector.detect_from_binary(image_data, mode: mode, min_prob: min_prob, debug_logs_enabled: debug_logs_enabled)
  end

end
