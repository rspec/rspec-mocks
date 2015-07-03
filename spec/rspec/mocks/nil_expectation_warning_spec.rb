module RSpec
  module Mocks
    RSpec.describe "an expectation set on nil" do
      it "issues a warning with file and line number information" do
        expected_warning = "WARNING: An expectation of :foo was set on nil. " \
          "To allow expectations on nil & suppress this message, set allow_expectations_on_nil to true. " \
          "To disallow expectations on nil, set allow_expectations_on_nil to false. Called from #{__FILE__}:#{__LINE__+3}(:in .+)?."
        expect(Kernel).to receive(:warn).with(/#{expected_warning}/)

        expect(nil).to receive(:foo)
        nil.foo
      end

      it "issues a warning when the expectation is negative" do
        expect(Kernel).to receive(:warn)

        expect(nil).not_to receive(:foo)
      end

      it 'does not issue a warning when expectations are set to be allowed' do
        allow_message_expectations_on_nil
        expect(Kernel).not_to receive(:warn)

        expect(nil).to receive(:foo)
        expect(nil).to_not receive(:bar)
        nil.foo
      end

      context 'configured to allow expectation on nil' do
        include_context 'with isolated configuration'

        it 'does not issue a warning when expectations are set to be allowed' do
          RSpec::Mocks.configuration.allow_message_expectations_on_nil = true
          expect(Kernel).not_to receive(:warn)

          expect(nil).to receive(:foo)
          expect(nil).not_to receive(:bar)
          nil.foo
        end
      end

      context 'configured to disallow expectations on nil' do
        include_context 'with isolated configuration'

        it "raises an error when expectations on nil are disallowed" do
          RSpec::Mocks.configuration.allow_message_expectations_on_nil = false
          expect { expect(nil).to receive(:foo)     }.to raise_error(RSpec::Mocks::MockExpectationError)
          expect { expect(nil).not_to receive(:bar) }.to raise_error(RSpec::Mocks::MockExpectationError)
        end
      end

      it 'does not call #nil? on a double extra times' do
        dbl = double
        expect(dbl).to receive(:nil?).once.and_return(false)
        dbl.nil?
      end
    end

    RSpec.describe "#allow_message_expectations_on_nil" do
      include_context "with monkey-patched marshal"

      it "does not affect subsequent examples" do
        allow_message_expectations_on_nil
        RSpec::Mocks.teardown
        RSpec::Mocks.setup
        expect(Kernel).to receive(:warn)
        expect(nil).to receive(:foo)
        nil.foo
      end

      it 'doesnt error when marshalled' do
        allow_message_expectations_on_nil
        expect(Marshal.dump(nil)).to eq Marshal.dump_without_rspec_mocks(nil)
      end
    end
  end
end
