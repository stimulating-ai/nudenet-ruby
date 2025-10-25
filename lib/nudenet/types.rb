# typed: strict
# frozen_string_literal: true

module NudeNet
  # Mode enum for detection processing modes
  class Mode < T::Enum
    enums do
      # Fast mode: max 320px on longest side, optimized for speed
      FAST = new("fast")
      # Slow mode: max 1333px on longest side, optimized for accuracy
      SLOW = new("slow")
    end
  end

  # Type aliases for cleaner signatures
  ImageInput = T.type_alias { T.any(String, Vips::Image) }
end
