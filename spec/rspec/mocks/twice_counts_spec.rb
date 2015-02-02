module RSpec
  module Mocks
    RSpec.describe "#twice" do
      before(:each) do
        @double = double("test double")
      end

      it "passes when called twice" do
        expect(@double).to receive(:do_something).twice
        @double.do_something
        @double.do_something
        verify @double
      end

      it "passes when called twice with specified args" do
        expect(@double).to receive(:do_something).twice.with("1", 1)
        @double.do_something("1", 1)
        @double.do_something("1", 1)
        verify @double
      end

      it "passes when called twice with unspecified args" do
        expect(@double).to receive(:do_something).twice
        @double.do_something("1")
        @double.do_something(1)
        verify @double
      end

      it "fails fast when call count is higher than expected" do
        expect(@double).to receive(:do_something).twice
        @double.do_something
        @double.do_something
        expect_fast_failure_from(@double) do
          @double.do_something
        end
      end

      it "fails when call count is lower than expected" do
        expect(@double).to receive(:do_something).twice
        @double.do_something
        expect {
          verify @double
        }.to raise_error(RSpec::Mocks::MockExpectationError)
      end

      it "fails when called with wrong args on the first call" do
        expect(@double).to receive(:do_something).twice.with("1", 1)
        expect {
          @double.do_something(1, "1")
        }.to raise_error(RSpec::Mocks::MockExpectationError)
        reset @double
      end

      it "fails when called with wrong args on the second call" do
        expect(@double).to receive(:do_something).twice.with("1", 1)
        @double.do_something("1", 1)
        expect {
          @double.do_something(1, "1")
        }.to raise_error(RSpec::Mocks::MockExpectationError)
        reset @double
      end
    end
  end
end
