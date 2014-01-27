require 'spec_helper'

module RSpec
  module Mocks
    describe "an expectation set on nil" do
      it "issues a warning with file and line number information" do
        expected_warning = %r%An expectation of :foo was set on nil. Called from #{__FILE__}:#{__LINE__+3}(:in .+)?. Use allow_message_expectations_on_nil to disable warnings.%
        Kernel.should_receive(:warn).with(expected_warning)

        nil.should_receive(:foo)
        nil.foo
      end

      it "issues a warning when the expectation is negative" do
        Kernel.should_receive(:warn)

        nil.should_not_receive(:foo)
      end

      it "does not issue a warning when expectations are set to be allowed" do
        allow_message_expectations_on_nil
        Kernel.should_not_receive(:warn)

        nil.should_receive(:foo)
        nil.should_not_receive(:bar)
        nil.foo
      end

      it 'does not call #nil? on a double extra times' do
        dbl = double
        dbl.should_receive(:nil?).once.and_return(false)
        dbl.nil?
      end
    end

    describe "#allow_message_expectations_on_nil" do
      it "does not affect subsequent examples" do
        allow_message_expectations_on_nil
        RSpec::Mocks.teardown
        RSpec::Mocks.setup
        Kernel.should_receive(:warn)
        nil.should_receive(:foo)
        nil.foo
      end

      it 'doesnt error when marshalled' do
        allow_message_expectations_on_nil
        expect(Marshal.dump(nil)).to eq Marshal.dump_without_mocks(nil)
      end
    end
  end
end
