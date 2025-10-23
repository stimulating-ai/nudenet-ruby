# typed: strict
# frozen_string_literal: true

module NudeNet
  # Type aliases for cleaner signatures
  Mode = T.type_alias { T.any(Symbol, String) }
  ImageInput = T.type_alias { T.any(String, Vips::Image) }
end
