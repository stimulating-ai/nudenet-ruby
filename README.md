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

results = NudeNet.detect('/path/to/image.jpg')
results.each do |detection|
  puts "Found #{detection.label} with confidence #{detection.score}"
  puts "Location: #{detection.box}"
end
```

### Fast Mode

Use fast mode for 3x speed with slightly lower accuracy:

```ruby
results = NudeNet.detect('/path/to/image.jpg', mode: :fast)
```

### Custom Confidence Threshold

```ruby
# Only return detections with confidence > 0.7
results = NudeNet.detect('/path/to/image.jpg', min_prob: 0.7)
```

### With MiniMagick

You can also pass a MiniMagick image object:

```ruby
require 'mini_magick'

image = MiniMagick::Image.open('/path/to/image.jpg')
results = NudeNet.detect(image)
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
  Thread.new { NudeNet.detect('image.jpg') }
end.each(&:join)
```

## Performance

- **Slow mode**: ~50-150ms per image (after initial load)
- **Fast mode**: ~30-50ms per image
- **First request per thread**: ~100-200ms (model initialization)
- **Memory per thread**: ~200-300MB

## Requirements

- Ruby >= 3.0.0
- ImageMagick (for MiniMagick)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`.

### Available Rake Tasks

- `rake spec` - Run the test suite
- `rake sorbet:check` - Run Sorbet type checker
- `rake sorbet:generate` - Generate RBI files using Tapioca
- `rake sorbet:all` - Generate RBI files and run type checker

## Credits

This is a Ruby port of the Python [nudenet-ruby](https://github.com/s0md3v/nudenet-ruby) library, which itself is a fork of [NudeNet](https://pypi.org/project/NudeNet/). The ONNX model is sourced from [s0md3v/nudity-checker](https://huggingface.co/s0md3v/nudity-checker) on HuggingFace.

## License

MIT License - see [LICENSE.md](LICENSE.md) for details.
