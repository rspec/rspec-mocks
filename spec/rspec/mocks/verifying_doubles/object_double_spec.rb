require 'support/doubled_classes'

module RSpec
  module Mocks
    RSpec.describe 'An object double' do
      it 'can replace an unloaded constant' do
        o = object_double("LoadedClass::NOINSTANCE").as_stubbed_const

        expect(LoadedClass::NOINSTANCE).to eq(o)

        expect(o).to receive(:undefined_instance_method)
        o.undefined_instance_method
      end

      it 'can replace a constant by name and verify instance methods' do
        o = object_double("LoadedClass::INSTANCE").as_stubbed_const

        expect(LoadedClass::INSTANCE).to eq(o)

        prevents { expect(o).to receive(:undefined_instance_method) }
        prevents { expect(o).to receive(:defined_class_method) }
        prevents { o.defined_instance_method }

        expect(o).to receive(:defined_instance_method)
        o.defined_instance_method
        expect(o).to receive(:defined_private_method)
        o.send :defined_private_method
      end

      it 'can create a double that matches the interface of any arbitrary object' do
        o = object_double(LoadedClass.new)

        prevents { expect(o).to receive(:undefined_instance_method) }
        prevents { expect(o).to receive(:defined_class_method) }
        prevents { o.defined_instance_method }

        expect(o).to receive(:defined_instance_method)
        o.defined_instance_method
        expect(o).to receive(:defined_private_method)
        o.send :defined_private_method
      end

      it 'does not allow transferring constants to an object' do
        expect {
          object_double("LoadedClass::INSTANCE").
            as_stubbed_const(:transfer_nested_constants => true)
        }.to raise_error(/Cannot transfer nested constants/)
      end

      it 'does not allow as_stubbed_constant for real objects' do
        expect {
          object_double(LoadedClass.new).as_stubbed_const
        }.to raise_error(/Can not perform constant replacement with an object/)
      end

      it 'is not a module' do
        expect(object_double("LoadedClass::INSTANCE")).to_not be_a(Module)
      end

      it 'validates `with` args against the method signature when stubbing a method' do
        dbl = object_double(LoadedClass.new)
        prevents(/Wrong number of arguments. Expected 2, got 3./) {
          allow(dbl).to receive(:instance_method_with_two_args).with(3, :foo, :args)
        }
      end
    end
  end
end
