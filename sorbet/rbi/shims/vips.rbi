# typed: strict

# Manual RBI for ruby-vips
module Vips
  class Image
    sig { params(path: String, opts: T.untyped).returns(Vips::Image) }
    def self.new_from_file(path, **opts); end

    sig { params(data: String, option_string: String, opts: T.untyped).returns(Vips::Image) }
    def self.new_from_buffer(data, option_string, **opts); end

    sig { returns(Integer) }
    def width; end

    sig { returns(Integer) }
    def height; end

    sig { params(scale: Float, vscale: T.nilable(Float), kernel: T.nilable(Symbol)).returns(Vips::Image) }
    def resize(scale, vscale: nil, kernel: nil); end

    sig { params(width: Integer, height: Integer, opts: T::Hash[Symbol, T.untyped]).returns(Vips::Image) }
    def thumbnail_image(width, height, **opts); end

    sig { returns(String) }
    def write_to_memory; end

    sig { params(opts: T.untyped).returns(T.untyped) }
    def colourspace(*opts); end
  end

  class Error < RuntimeError; end
end
