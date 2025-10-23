# frozen_string_literal: true

RSpec.describe NudeNet::Detector do
  let(:test_image_path) { File.expand_path("fixtures/nude/nude1.jpg", __dir__) }

  describe "thread safety" do
    it "handles concurrent requests without crashes" do
      threads = 10.times.map do
        Thread.new do
          result = NudeNet.detect_from_path(test_image_path)
          expect(result).to be_an(Array)
        end
      end

      expect { threads.each(&:join) }.not_to raise_error
    end

    it "creates separate sessions per thread" do
      sessions = []
      mutex = Mutex.new

      threads = 5.times.map do
        Thread.new do
          NudeNet.detect_from_path(test_image_path)
          session_id = Thread.current[:nudenet_session].object_id
          mutex.synchronize { sessions << session_id }
        end
      end

      threads.each(&:join)

      # Each thread should have its own session
      expect(sessions.uniq.size).to eq(5)
    end

    it "reuses session within the same thread" do
      NudeNet.detect_from_path(test_image_path)
      first_session = Thread.current[:nudenet_session].object_id

      NudeNet.detect_from_path(test_image_path)
      second_session = Thread.current[:nudenet_session].object_id

      expect(first_session).to eq(second_session)
    end
  end
end
