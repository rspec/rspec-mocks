module RSpec
  module Mocks
    RSpec.describe "Mocking Mutex" do
      let(:mocked_mutex) { instance_double(Mutex) }
      before do
        allow(Mutex).to receive(:new).and_return(mocked_mutex)
        allow(mocked_mutex).to receive(:synchronize).and_yield
      end

      it "successfully yields" do
        called = false
        mutex = Mutex.new
        mutex.synchronize { called = true }
        expect(called).to be_truthy
      end
    end
  end
end
