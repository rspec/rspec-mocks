module RSpec
  module Mocks
    RSpec.describe "#once" do
      before(:each) do
        @double = double
      end

      it "passes when called once" do
        expect(@double).to receive(:do_something).once
        @double.do_something
        verify @double
      end

      it "passes when called once with specified args" do
        expect(@double).to receive(:do_something).once.with("a", "b", "c")
        @double.do_something("a", "b", "c")
        verify @double
      end

      it "passes when called once with unspecified args" do
        expect(@double).to receive(:do_something).once
        @double.do_something("a", "b", "c")
        verify @double
      end

      it "fails when called with wrong args" do
        expect(@double).to receive(:do_something).once.with("a", "b", "c")
        expect {
          @double.do_something("d", "e", "f")
        }.to raise_error(RSpec::Mocks::MockExpectationError)
        reset @double
      end

      it "fails fast when called twice" do
        expect(@double).to receive(:do_something).once
        @double.do_something
        expect_fast_failure_from(@double) do
          @double.do_something
        end
      end

      it "fails when not called" do
        expect(@double).to receive(:do_something).once
        expect {
          verify @double
        }.to raise_error(RSpec::Mocks::MockExpectationError)
      end
    end
  end
end
