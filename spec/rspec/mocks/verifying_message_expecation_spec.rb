require 'spec_helper'

module RSpec
  module Mocks
    describe VerifyingMessageExpectation do
      describe '#with' do
        let(:method_tracer) { Object.new }

        subject {
          null = double.as_null_object

          described_class.new(null, null, null, null)
        }

        describe 'when expected method is not loaded' do
          it 'allows any arguments to be expected' do
            subject.with(:foo, :bar)

            expect(subject.failed_fast?).not_to eq(true)
          end
        end

        describe 'when arity match fails' do
          it 'raises error and fails fast' do
            expect(ArityMatcher).to receive(:match!).
              and_raise(RSpec::Expectations::ExpectationNotMetError)

            expect {
              subject.with(nil)
            }.to raise_error(RSpec::Expectations::ExpectationNotMetError)

            expect(subject.failed_fast?).to eq(true)
          end
        end

        describe 'when called with arguments' do
          it 'matches arity against the number of arguments' do
            subject.method_finder = proc { method_tracer }

            expect(ArityMatcher).to receive(:match!).with(method_tracer, 2)

            subject.with(nil, nil)
          end
        end

        describe 'when called with any arguments matcher' do
          it 'does not try to match arity' do
            expect(ArityMatcher).not_to receive(:match!)

            subject.with(any_args)
          end
        end

        describe 'when called with no arguments matcher' do
          it 'matches arity to 0' do
            subject.method_finder = proc { method_tracer }

            expect(ArityMatcher).to receive(:match!).with(method_tracer, 0)

            subject.with(no_args)
          end
        end

        describe 'when called with a block' do
          it 'matches arity against the arity of the block' do
            subject.method_finder = proc { method_tracer }

            expect(ArityMatcher).to receive(:match!).with(method_tracer, 2)

            subject.with {|_, _| }
          end
        end

        describe 'when called with no arguments and no block' do
          it 'raises' do
            expect {
              subject.with
            }.to raise_error(ArgumentError, "No arguments nor block given.")
          end
        end
      end
    end
  end
end
