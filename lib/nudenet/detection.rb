# typed: strict
# frozen_string_literal: true

module NudeNet
  # Detection label enum for all possible classes
  class DetectionLabel < T::Enum
    enums do
      FemaleGenitaliaExposed = new("FEMALE_GENITALIA_EXPOSED")
      FemaleGenitaliaCovered = new("FEMALE_GENITALIA_COVERED")
      FemaleBreastExposed = new("FEMALE_BREAST_EXPOSED")
      FemaleBreastCovered = new("FEMALE_BREAST_COVERED")
      MaleGenitaliaExposed = new("MALE_GENITALIA_EXPOSED")
      MaleBreastExposed = new("MALE_BREAST_EXPOSED")
      AnusExposed = new("ANUS_EXPOSED")
      AnusCovered = new("ANUS_COVERED")
      ButtocksExposed = new("BUTTOCKS_EXPOSED")
      ButtocksCovered = new("BUTTOCKS_COVERED")
      BellyExposed = new("BELLY_EXPOSED")
      BellyCovered = new("BELLY_COVERED")
      FeetExposed = new("FEET_EXPOSED")
      FeetCovered = new("FEET_COVERED")
      ArmpitsExposed = new("ARMPITS_EXPOSED")
      ArmpitsCovered = new("ARMPITS_COVERED")
      FaceFemale = new("FACE_FEMALE")
      FaceMale = new("FACE_MALE")
    end
  end

  # Represents a single detection result
  class Detection < T::Struct
    extend T::Sig

    # Bounding box coordinates [x1, y1, x2, y2]
    const :box, T::Array[Integer]

    # Confidence score (0.0 to 1.0)
    const :score, Float

    # Label/class name (e.g., "FEMALE_BREAST_EXPOSED")
    const :label, DetectionLabel

    sig { returns(String) }
    def to_s
      "#<NudeNet::Detection box=#{box} score=#{score.round(3)} label=#{label.serialize.inspect}>"
    end

    sig { returns(T::Hash[Symbol, T.untyped]) }
    def to_h
      { box: box, score: score, label: label.serialize }
    end
  end
end
