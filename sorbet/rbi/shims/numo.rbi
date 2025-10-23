# typed: strict

# Manual RBI for numo-narray
module Numo
  class NArray
    sig { params(data: T.untyped).returns(Numo::NArray) }
    def self.cast(data); end

    sig { params(dims: Integer).returns(Numo::NArray) }
    def self.zeros(*dims); end

    sig { returns(T::Array[Integer]) }
    def shape; end

    sig { params(dims: Integer).returns(Numo::NArray) }
    def reshape(*dims); end

    sig { params(axes: Integer).returns(Numo::NArray) }
    def transpose(*axes); end

    sig { params(indices: T.untyped).returns(T.untyped) }
    def [](*indices); end

    sig { params(indices: T.untyped, value: T.untyped).returns(T.untyped) }
    def []=(*indices, value); end

    sig { returns(Numeric) }
    def max; end

    sig { returns(T::Array[T.untyped]) }
    def to_a; end

    sig { params(other: Numeric).returns(Numo::NArray) }
    def /(other); end
  end

  class SFloat < NArray
    sig { params(binary: String).returns(Numo::SFloat) }
    def self.from_binary(binary); end

    sig { params(data: T.untyped).returns(Numo::SFloat) }
    def self.cast(data); end

    sig { params(dims: Integer).returns(Numo::SFloat) }
    def self.zeros(*dims); end

    sig { params(dims: Integer).returns(Numo::SFloat) }
    def reshape(*dims); end

    sig { params(axes: Integer).returns(Numo::SFloat) }
    def transpose(*axes); end

    sig { params(type: T.untyped).returns(Numo::SFloat) }
    def cast_to(type); end

    sig { params(other: Numeric).returns(Numo::SFloat) }
    def /(other); end
  end

  class UInt8 < NArray
    sig { params(binary: String).returns(Numo::UInt8) }
    def self.from_binary(binary); end

    sig { params(dims: Integer).returns(Numo::UInt8) }
    def reshape(*dims); end

    sig { params(type: T.untyped).returns(Numo::SFloat) }
    def cast_to(type); end
  end
end
