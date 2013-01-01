require 'spec_helper'

module RSpec
  module Mocks
    describe "#once" do
      before(:each) do
        @double = double
      end

      it "passes when called once" do
        @double.should_receive(:do_something).once
        @double.do_something
        @double.rspec_verify
      end

      it "passes when called once with specified args" do
        @double.should_receive(:do_something).once.with("a", "b", "c")
        @double.do_something("a", "b", "c")
        @double.rspec_verify
      end

      it "passes when called once with unspecified args" do
        @double.should_receive(:do_something).once
        @double.do_something("a", "b", "c")
        @double.rspec_verify
      end

      it "fails when called with wrong args" do
        @double.should_receive(:do_something).once.with("a", "b", "c")
        expect {
          @double.do_something("d", "e", "f")
        }.to raise_error(RSpec::Mocks::MockExpectationError)
        @double.rspec_reset
      end

      it "fails fast when called twice" do
        @double.should_receive(:do_something).once
        @double.do_something
        expect {
          @double.do_something
        }.to raise_error(RSpec::Mocks::MockExpectationError)
      end

      it "fails when not called" do
        @double.should_receive(:do_something).once
        expect {
          @double.rspec_verify
        }.to raise_error(RSpec::Mocks::MockExpectationError)
      end
    end
  end
end
