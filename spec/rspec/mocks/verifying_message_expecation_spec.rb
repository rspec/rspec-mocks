require 'spec_helper'

module RSpec
  module Mocks
    describe VerifyingMessageExpectation do
      describe '#with' do
        let(:error_generator) { double.as_null_object }
        let(:string_module_reference) { DirectModuleReference.new(String) }

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
            args = ["abc123", "xyz987"]
            subject.method_reference = InstanceMethodReference.new(string_module_reference, :replace)
            expect(error_generator).to receive(:raise_invalid_arguments_error).
              with(instance_of(MethodSignatureVerifier))

            subject.with(*args)
          end
        end

        describe 'when called with arguments' do
          it 'matches arity against the number of arguments' do
            subject.method_reference = InstanceMethodReference.new(string_module_reference, :replace)
            expect(error_generator).not_to receive(:raise_invalid_arguments_error)

            subject.with("abc123")
          end
        end

        describe 'when called with any arguments matcher' do
          it 'does not try to match arity' do
            subject.method_reference = InstanceMethodReference.new(string_module_reference, :replace)
            subject.with(any_args)
          end
        end

        describe 'when called with no arguments matcher' do
          it 'matches arity to 0' do
            subject.method_reference = InstanceMethodReference.new(string_module_reference, :replace)
            expect(error_generator).to receive(:raise_invalid_arguments_error).
              with(instance_of(MethodSignatureVerifier))

            subject.with(no_args)
          end
        end

        describe 'when called with no arguments and no block' do
          it 'raises' do
            expect {
              subject.with
            }.to raise_error(ArgumentError)
          end
        end
      end
    end
  end
end
