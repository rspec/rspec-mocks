require 'spec_helper'

module RSpec
  module Mocks
    describe VerifyingMessageExpectation do
      describe '#with' do
        let(:method_tracer) { Object.new }
        let(:error_generator) { double.as_null_object }

        subject {
          null = double.as_null_object

          described_class.new(error_generator, null, null, null)
        }

        describe 'when expected method is not loaded' do
          it 'allows any arguments to be expected' do
            subject.with(:foo, :bar)
          end
        end

        describe 'when arity match fails' do
          it 'raises error' do
            subject.method_finder = Proc.new { lambda {|_| } }
            expect(error_generator).to receive(:raise_arity_error).
              with(instance_of(ArityCalculator), 2)

            subject.with(nil, nil)
          end
        end

        describe 'when called with arguments' do
          it 'matches arity against the number of arguments' do
            subject.method_finder = Proc.new { lambda {|_| } }
            expect(error_generator).not_to receive(:raise_arity_error)

            subject.with(nil)
          end
        end

        describe 'when called with any arguments matcher' do
          it 'does not try to match arity' do
            subject.method_finder = Proc.new { raise }
            subject.with(any_args)
          end
        end

        describe 'when called with no arguments matcher' do
          it 'matches arity to 0' do
            subject.method_finder = Proc.new { lambda {|_| } }
            expect(error_generator).to receive(:raise_arity_error).
              with(instance_of(ArityCalculator), 0)

            subject.with(no_args)
          end
        end

        describe 'when called with a block' do
          it 'matches arity against the arity of the block' do
            subject.method_finder = Proc.new { lambda {|_| } }
            expect(error_generator).to receive(:raise_arity_error).
              with(instance_of(ArityCalculator), 2)

            subject.with {|x, y| }
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
