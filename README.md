# NudeNet Ruby - Fast nudity detection

A neural network powered Ruby gem that detects nudity in images of both real humans and drawings. It takes an image as input and tells you exactly what NSFW parts of the body are visible.

<img src="https://i.imgur.com/0KPJbl9.jpg" width=600>

## Features

- **Fast & Accurate**: Uses ONNX neural network for efficient inference
- **Thread-Safe**: Perfect for multi-threaded API servers (Puma, Falcon, etc.)
- **Type-Safe**: Built with Sorbet for complete type safety
- **Zero Configuration**: Model bundled with gem, no downloads needed
- **Simple API**: One method to detect nudity

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'nudenet-ruby'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install nudenet-ruby

## Usage

### Basic Detection

```ruby
require 'nudenet-ruby'

results = NudeNet.detect_from_path('/path/to/image.jpg')
results.each do |detection|
  puts "Found #{detection.label} with confidence #{detection.score}"
  puts "Location: #{detection.box}"
end
```

### Detection Modes

Fast mode (default) provides 2-3x speed with good accuracy. Use slow mode for maximum accuracy:

```ruby
# Fast mode (default)
results = NudeNet.detect_from_path('/path/to/image.jpg', mode: :fast)

# Slow mode (more accurate)
results = NudeNet.detect_from_path('/path/to/image.jpg', mode: :slow)
```

### Custom Confidence Threshold

Adjust the minimum confidence threshold (default: 0.25):

```ruby
# Only return detections with confidence > 0.7 (fewer false positives)
results = NudeNet.detect_from_path('/path/to/image.jpg', min_prob: 0.7)

# Lower threshold for higher sensitivity (more detections)
results = NudeNet.detect_from_path('/path/to/image.jpg', min_prob: 0.15)
```

### Detect from Binary Data

You can also detect from binary image data (useful for URLs, uploads, etc.):

```ruby
require 'open-uri'

# From URL
image_data = URI.open('https://example.com/image.jpg').read
results = NudeNet.detect_image_data(image_data)

# From file upload
image_data = File.binread('/path/to/image.jpg')
results = NudeNet.detect_image_data(image_data)
```

## Output Format

Each detection is an `NudeNet::Detection` struct with:

- `box`: Array of 4 integers `[x1, y1, x2, y2]` representing the bounding box
- `score`: Float between 0.0 and 1.0 representing confidence
- `label`: String label for the detected body part

```ruby
#<NudeNet::Detection box=[164, 188, 246, 271] score=0.825 label="EXPOSED_BREAST_F">
```

### Possible Labels

- `EXPOSED_BREAST_F` - Female breast
- `EXPOSED_BREAST_M` - Male breast
- `EXPOSED_BUTTOCKS` - Buttocks
- `EXPOSED_GENITALIA_F` - Female genitalia
- `EXPOSED_GENITALIA_M` - Male genitalia

Note: `EXPOSED_BELLY` is filtered out by default.

## Thread Safety

This gem is designed to be thread-safe for use in API servers. Each thread maintains its own ONNX inference session:

```ruby
# Safe in multi-threaded environments
10.times.map do
  Thread.new { NudeNet.detect_from_path('image.jpg') }
end.each(&:join)
```

## Performance

- **Slow mode**: ~50-150ms per image (after initial load)
- **Fast mode**: ~30-50ms per image
- **First request per thread**: ~100-200ms (model initialization)
- **Memory per thread**: ~200-300MB

## Requirements

- Ruby >= 3.0.0
- libvips >= 8.0 (for image processing)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`.

### Available Rake Tasks

- `rake spec` - Run the test suite
- `rake sorbet:check` - Run Sorbet type checker
- `rake sorbet:generate` - Generate RBI files using Tapioca
- `rake sorbet:all` - Generate RBI files and run type checker

## Credits

This is a Ruby port of NudeNet. The ONNX model is sourced from [notAI-tech/NudeNet](https://github.com/notAI-tech/NudeNet/releases).

## License

MIT License - see [LICENSE.md](LICENSE.md) for details.
