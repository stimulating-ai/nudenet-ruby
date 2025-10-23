# typed: strict

# Manual RBI for onnxruntime
module OnnxRuntime
  class InferenceSession
    sig { params(path: String, providers: T.nilable(T::Array[String])).void }
    def initialize(path, providers: nil); end

    sig { returns(T::Array[T::Hash[Symbol, T.untyped]]) }
    def inputs; end

    sig { returns(T::Array[T::Hash[Symbol, T.untyped]]) }
    def outputs; end

    sig do
      params(
        output_names: T.nilable(T::Array[String]),
        input_feed: T::Hash[String, T.untyped]
      ).returns(T::Array[T.untyped])
    end
    def run(output_names, input_feed); end
  end
end
