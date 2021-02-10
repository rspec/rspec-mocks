module RSpec
  module Mocks
    RSpec.describe "an expectation set on nil" do
      it "issues a warning with file and line number information" do
        expect {
          expect(nil).to receive(:foo)
        }.to output(a_string_including(
          "An expectation of `:foo` was set on `nil`",
          "#{__FILE__}:#{__LINE__ - 3}"
        )).to_stderr

        nil.foo
      end

      it "issues a warning when the expectation is negative" do
        expect {
          expect(nil).not_to receive(:foo)
        }.to output(a_string_including(
          "An expectation of `:foo` was set on `nil`",
          "#{__FILE__}:#{__LINE__ - 3}"
        )).to_stderr
      end

      context 'configured to allow expectation on nil' do
        include_context 'with isolated configuration'

        before { RSpec::Mocks.configuration.allow_message_expectations_on_nil = true }

        it 'does not issue a warning when expectations are set to be allowed' do
          expect {
            expect(nil).to receive(:foo)
            expect(nil).not_to receive(:bar)
          }.not_to output.to_stderr

          nil.foo
        end

        describe "marshalled `nil`" do
          include_context "with monkey-patched marshal"

          it 'doesnt error when marshalled' do
            expect(Marshal.dump(nil)).to eq Marshal.dump_without_rspec_mocks(nil)
          end
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
  end
end
