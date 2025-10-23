# frozen_string_literal: true

RSpec.describe NudeNet::Detection do
  let(:detection) do
    described_class.new(
      box: [100, 200, 300, 400],
      score: 0.8523,
      label: NudeNet::DetectionLabel::FemaleBreastExposed
    )
  end

  describe "#to_s" do
    it "returns a readable string representation" do
      expect(detection.to_s).to include("Detection")
      expect(detection.to_s).to include("0.852")
      expect(detection.to_s).to include("FEMALE_BREAST_EXPOSED")
    end
  end

  describe "#to_h" do
    it "returns a hash representation" do
      hash = detection.to_h
      expect(hash[:box]).to eq([100, 200, 300, 400])
      expect(hash[:score]).to eq(0.8523)
      expect(hash[:label]).to eq("FEMALE_BREAST_EXPOSED")
    end
  end

  describe "struct behavior" do
    it "is immutable" do
      expect { detection.box = [1, 2, 3, 4] }.to raise_error(NoMethodError)
    end

    it "allows access to properties" do
      expect(detection.box).to eq([100, 200, 300, 400])
      expect(detection.score).to eq(0.8523)
      expect(detection.label).to eq(NudeNet::DetectionLabel::FemaleBreastExposed)
    end
  end
end
