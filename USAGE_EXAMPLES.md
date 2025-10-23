# NudeNet Ruby Usage Examples

## API Methods

### `NudeNet.detect_from_path(image_uri, **options)`

Detect nudity from a local file path.

**Parameters:**

- `image_uri` (String) - Local file path to image
- `mode` (Symbol) - `:fast` (default) or `:slow`
- `min_prob` (Float) - Minimum confidence threshold (default: 0.5)
- `debug_logs_enabled` (Boolean) - Enable timing logs (default: false)

**Returns:** Array of `NudeNet::Detection` objects

---

### `NudeNet.detect_image_data(image_data, **options)`

Detect nudity from binary image data (JPEG, PNG, etc.).

**Parameters:**

- `image_data` (String) - Binary image data
- `mode` (Symbol) - `:fast` (default) or `:slow`
- `min_prob` (Float) - Minimum confidence threshold (default: 0.5)
- `debug_logs_enabled` (Boolean) - Enable timing logs (default: false)

**Returns:** Array of `NudeNet::Detection` objects

---

## Examples

### 1. Basic Detection from File

```ruby
require 'nudenet-ruby'

results = NudeNet.detect_from_path('/path/to/image.jpg')

results.each do |detection|
  puts "Found #{detection.label}"
  puts "  Confidence: #{(detection.score * 100).round(1)}%"
  puts "  Location: #{detection.box}"
end
```

### 2. Detection from Downloaded URL

```ruby
require 'nudenet-ruby'
require 'open-uri'

# Download image data
image_data = URI.open('https://example.com/image.jpg').read

# Detect nudity
results = NudeNet.detect_image_data(image_data)

if results.empty?
  puts "✅ Image is safe"
else
  puts "⚠️  NSFW content detected:"
  results.each do |detection|
    puts "  - #{detection.label} (#{(detection.score * 100).round}%)"
  end
end
```

### 3. Detection from Rails Upload

```ruby
# In a Rails controller
class ImageModerationController < ApplicationController
  def check_upload
    # Get uploaded file data
    uploaded_file = params[:image]
    image_data = uploaded_file.read

    # Detect nudity
    results = NudeNet.detect_image_data(image_data)

    if results.any?
      render json: {
        safe: false,
        detections: results.map(&:to_h)
      }
    else
      render json: { safe: true }
    end
  end
end
```

### 4. Batch Processing with Threading

```ruby
require 'nudenet-ruby'

image_paths = Dir.glob('images/**/*.jpg')

# Process in parallel (thread-safe)
results = image_paths.map do |path|
  Thread.new do
    {
      path: path,
      detections: NudeNet.detect_from_path(path)
    }
  end
end.map(&:value)

# Report
results.each do |result|
  if result[:detections].any?
    puts "⚠️  #{result[:path]} - NSFW (#{result[:detections].length} detections)"
  end
end
```

### 5. Custom Threshold

```ruby
require 'nudenet-ruby'

# High sensitivity (more false positives)
results = NudeNet.detect_from_path('image.jpg', min_prob: 0.3)

# Low sensitivity (fewer false positives, may miss some)
results = NudeNet.detect_from_path('image.jpg', min_prob: 0.8)
```

### 6. Performance Monitoring

```ruby
require 'nudenet-ruby'

results = NudeNet.detect_from_path(
  'image.jpg',
  debug_logs_enabled: true
)

# Output:
# [NudeNet] Preprocessing: 453.5ms
# [NudeNet] Inference: 577.3ms
```

### 7. AWS S3 Integration

```ruby
require 'nudenet-ruby'
require 'aws-sdk-s3'

s3 = Aws::S3::Client.new
response = s3.get_object(bucket: 'my-bucket', key: 'user-upload.jpg')

# Detect from S3 data
results = NudeNet.detect_image_data(response.body.read)

if results.any?
  # Flag or move the object
  s3.put_object_tagging(
    bucket: 'my-bucket',
    key: 'user-upload.jpg',
    tagging: { tag_set: [{ key: 'nsfw', value: 'true' }] }
  )
end
```

### 8. ActiveStorage Integration

```ruby
class User < ApplicationRecord
  has_one_attached :avatar

  validate :avatar_must_be_safe

  private

  def avatar_must_be_safe
    return unless avatar.attached?

    # Download avatar data
    image_data = avatar.download

    # Check for nudity
    results = NudeNet.detect_image_data(image_data)

    if results.any?
      errors.add(:avatar, "contains inappropriate content")
    end
  end
end
```

### 9. Streaming from API

```ruby
require 'nudenet-ruby'
require 'net/http'

uri = URI('https://example.com/image.jpg')
response = Net::HTTP.get_response(uri)

if response.is_a?(Net::HTTPSuccess)
  results = NudeNet.detect_image_data(response.body)
  puts results.inspect
end
```

### 10. Background Job Processing

```ruby
class ImageModerationJob < ApplicationJob
  queue_as :slow

  def perform(image_url)
    # Download image
    image_data = URI.open(image_url).read

    # Detect nudity
    results = NudeNet.detect_image_data(image_data)

    # Store results
    ImageModeration.create!(
      url: image_url,
      nsfw: results.any?,
      detections: results.map(&:to_h)
    )
  end
end

# Enqueue
ImageModerationJob.perform_later('https://example.com/upload.jpg')
```

## Performance Tips

1. **Use `detect_image_data` when downloading from URLs** - Slightly faster than saving to disk first
2. **Enable debug logs in development** - Helps identify bottlenecks
3. **Fast mode is default** - ~2x faster than slow mode
4. **Thread-safe** - Safe to use in multi-threaded servers (Puma, Falcon)
5. **Smaller images = faster** - Resize before detection if possible

## Detection Object

```ruby
detection = results.first

detection.box      # => [x1, y1, x2, y2] - Bounding box coordinates
detection.score    # => 0.658 - Confidence score (0.0 to 1.0)
detection.label    # => "EXPOSED_BREAST_F" - Detection class

detection.to_h     # => { box: [...], score: 0.658, label: "..." }
detection.to_s     # => "#<NudeNet::Detection box=[...] score=0.658 label=\"...\">"
```

## Possible Labels

- `EXPOSED_BREAST_F` - Female breast
- `EXPOSED_BREAST_M` - Male breast
- `EXPOSED_BUTTOCKS` - Buttocks
- `EXPOSED_GENITALIA_F` - Female genitalia
- `EXPOSED_GENITALIA_M` - Male genitalia

Note: `EXPOSED_BELLY` is filtered out by default.
