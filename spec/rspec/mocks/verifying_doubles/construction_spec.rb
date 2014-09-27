require 'support/doubled_classes'

module RSpec
  module Mocks
    RSpec.describe 'Constructing a verifying double' do
      describe 'instance doubles' do
        it 'cannot be constructed with a non-module object' do
          expect {
            instance_double(Object.new)
          }.to raise_error(/Module or String expected/)
        end

        it 'can be constructed with a struct' do
          o = instance_double(Struct.new(:defined_method), :defined_method => 1)

          expect(o.defined_method).to eq(1)
        end
      end

      describe 'class doubles' do
        it 'cannot be constructed with a non-module object' do
          expect {
            class_double(Object.new)
          }.to raise_error(/Module or String expected/)
        end
      end

      describe 'when verify_doubled_constant_names config option is set' do
        include_context "with isolated configuration"

        before do
          RSpec::Mocks.configuration.verify_doubled_constant_names = true
        end

        it 'prevents creation of instance doubles for unloaded constants' do
          expect {
            instance_double('LoadedClas')
          }.to raise_error(VerifyingDoubleNotDefinedError)
        end

        it 'prevents creation of class doubles for unloaded constants' do
          expect {
            class_double('LoadedClas')
          }.to raise_error(VerifyingDoubleNotDefinedError)
        end
      end

      it 'can only be named with a string or a module' do
        expect { instance_double(1) }.to raise_error(ArgumentError)
        expect { instance_double(nil) }.to raise_error(ArgumentError)
      end
    end
  end
end
