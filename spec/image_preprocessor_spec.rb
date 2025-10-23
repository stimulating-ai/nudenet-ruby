# frozen_string_literal: true

RSpec.describe NudeNet::ImagePreprocessor do
  let(:test_image_path) { File.expand_path("fixtures/nude/nude1.jpg", __dir__) }

  describe "#preprocess" do
    context "with default mode" do
      it "returns preprocessed image and scale" do
        preprocessor = described_class.new(test_image_path, mode: :slow)
        image, scale = preprocessor.preprocess

        expect(image).to be_a(Numo::SFloat)
        expect(scale).to be_a(Float)
        expect(scale).to be > 0
        expect(image.ndim).to eq(3)
        expect(image.shape[0]).to eq(3) # 3 channels (RGB in NCHW format)
      end

      it "resizes to max 1333 on longest side" do
        preprocessor = described_class.new(test_image_path, mode: :slow)
        image, _scale = preprocessor.preprocess

        expect([image.shape[1], image.shape[2]].max).to be <= 1333
      end
    end

    context "with fast mode" do
      it "resizes to max 320 on longest side" do
        preprocessor = described_class.new(test_image_path, mode: :fast)
        image, _scale = preprocessor.preprocess

        expect([image.shape[1], image.shape[2]].max).to be <= 320
      end
    end
  end
end
