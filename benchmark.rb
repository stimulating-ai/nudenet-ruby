#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/nudenet"

test_image = "spec/fixtures/nude/nude1.jpg"

puts "Testing inference optimizations (CPU only):\n\n"

# Warmup
puts "Warming up..."
NudeNet.detect_from_path(test_image)

puts "\nRunning 10 inferences with optimizations:\n"
times = []
10.times do |i|
  start = Time.now
  result = NudeNet.detect_from_path(test_image, debug_logs_enabled: false)
  elapsed = ((Time.now - start) * 1000).round(1)
  times << elapsed
  puts "  Run #{i + 1}: #{elapsed}ms (#{result.length} detections)"
end

avg = (times.sum / times.length).round(1)
min_time = times.min.round(1)
max_time = times.max.round(1)

puts "\n" + "=" * 60
puts "RESULTS"
puts "=" * 60
puts "Average: #{avg}ms"
puts "Min:     #{min_time}ms"
puts "Max:     #{max_time}ms"
puts "\nOptimizations applied:"
puts "  ✓ Cached class names (loaded once, not per inference)"
puts "  ✓ Cached input name per thread"
puts "  ✓ Using reshape() instead of zeros() + copy for batch dimension"
puts ""
puts "Expected improvement: 5-15ms per inference"
