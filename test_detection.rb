#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require_relative "lib/nudenet"

puts "Testing NudeNet Ruby v#{NudeNet::VERSION}"
puts "=" * 60

# Define explicit nudity labels
EXPLICIT_LABELS = [
  NudeNet::DetectionLabel::FemaleBreastExposed,
  NudeNet::DetectionLabel::FemaleGenitaliaExposed,
  NudeNet::DetectionLabel::MaleGenitaliaExposed,
  NudeNet::DetectionLabel::AnusExposed
].freeze

# Test nude images
puts "\n🔴 Testing NUDE images:"
Dir.glob("spec/fixtures/nude/*.jpg").sort.each do |image_path|
  filename = File.basename(image_path)
  print "  #{filename.ljust(15)} => "

  begin
    all_detections = NudeNet.detect_from_path(image_path)
    results = all_detections.select { |d| EXPLICIT_LABELS.include?(d.label) }
    if results.empty?
      puts "❌ No detections (FALSE NEGATIVE)"
    else
      puts "✅ #{results.size} detection(s)"
      results.each do |det|
        puts "      - #{det.label.serialize} (#{(det.score * 100).round(1)}%)"
      end
    end
  rescue => e
    puts "💥 Error: #{e.message}"
  end
end

# Test non-nude images
puts "\n🟢 Testing NON-NUDE images:"
Dir.glob("spec/fixtures/non_nude/*.jpg").sort.each do |image_path|
  filename = File.basename(image_path)
  print "  #{filename.ljust(15)} => "

  begin
    all_detections = NudeNet.detect_from_path(image_path)
    results = all_detections.select { |d| EXPLICIT_LABELS.include?(d.label) }
    if results.empty?
      puts "✅ No detections (correct)"
    else
      puts "⚠️  #{results.size} detection(s) (FALSE POSITIVE)"
      results.each do |det|
        puts "      - #{det.label.serialize} (#{(det.score * 100).round(1)}%)"
      end
    end
  rescue => e
    puts "💥 Error: #{e.message}"
  end
end

# Test thread safety
puts "\n🧵 Testing thread safety (10 concurrent threads):"
threads = 10.times.map do |i|
  Thread.new do
    image = Dir.glob("spec/fixtures/**/*.jpg").sample
    results = NudeNet.detect_from_path(image)
    print "."
    results
  end
end

thread_results = threads.map(&:value)
puts " ✅ All threads completed successfully"

# Test fast mode
puts "\n⚡ Testing fast mode:"
test_image = Dir.glob("spec/fixtures/nude/*.jpg").first
if test_image
  require "benchmark"

  default_time = Benchmark.realtime { NudeNet.detect_from_path(test_image, mode: :slow) }
  fast_time = Benchmark.realtime { NudeNet.detect_from_path(test_image, mode: :fast) }

  puts "  Slow mode:    #{(default_time * 1000).round(1)}ms"
  puts "  Fast mode:    #{(fast_time * 1000).round(1)}ms"
  puts "  Speedup:      #{(default_time / fast_time).round(2)}x"
end

puts "\n" + "=" * 60
puts "✅ Testing complete!"
