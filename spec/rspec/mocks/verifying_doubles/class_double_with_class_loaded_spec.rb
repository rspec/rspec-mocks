require 'support/doubled_classes'

module RSpec
  module Mocks
    RSpec.describe 'A class double with the doubled class loaded' do
      include_context "with isolated configuration"

      before do
        RSpec::Mocks.configuration.verify_doubled_constant_names = true
      end

      it 'only allows class methods that exist to be stubbed' do
        o = class_double('LoadedClass', :defined_class_method => 1)
        expect(o.defined_class_method).to eq(1)

        prevents { allow(o).to receive(:undefined_instance_method) }
        prevents { allow(o).to receive(:defined_instance_method) }
      end

      it 'only allows class methods that exist to be expected' do
        o = class_double('LoadedClass')
        expect(o).to receive(:defined_class_method)
        o.defined_class_method

        prevents { expect(o).to receive(:undefined_instance_method) }
        prevents { expect(o).to receive(:defined_instance_method) }
        prevents { expect(o).to receive(:undefined_instance_method) }
        prevents { expect(o).to receive(:defined_instance_method) }
      end

      it 'gives a descriptive error message for NoMethodError' do
        o = class_double("LoadedClass")
        expect {
          o.defined_private_class_method
        }.to raise_error(NoMethodError, /Double "LoadedClass"/)
      end

      it 'checks that stubbed methods are invoked with the correct arity' do
        o = class_double('LoadedClass', :defined_class_method => 1)
        expect {
          o.defined_class_method(:a)
        }.to raise_error(ArgumentError)
      end

      it 'allows dynamically defined class method stubs with arguments' do
        o = class_double('LoadedClass')
        allow(o).to receive(:dynamic_class_method).with(:a) { 1 }

        expect(o.dynamic_class_method(:a)).to eq(1)
      end

      it 'allows dynamically defined class method mocks with arguments' do
        o = class_double('LoadedClass')
        expect(o).to receive(:dynamic_class_method).with(:a)

        o.dynamic_class_method(:a)
      end

      it 'allows dynamically defined class methods to be expected' do
        o = class_double('LoadedClass', :dynamic_class_method => 1)
        expect(o.dynamic_class_method).to eq(1)
      end

      it 'allows class to be specified by constant' do
        o = class_double(LoadedClass, :defined_class_method => 1)
        expect(o.defined_class_method).to eq(1)
      end

      it 'can replace existing constants for the duration of the test' do
        original = LoadedClass
        object = class_double('LoadedClass').as_stubbed_const
        expect(object).to receive(:defined_class_method)

        expect(LoadedClass).to eq(object)
        ::RSpec::Mocks.teardown
        ::RSpec::Mocks.setup
        expect(LoadedClass).to eq(original)
      end

      it 'can transfer nested constants to the double' do
        class_double("LoadedClass").
          as_stubbed_const(:transfer_nested_constants => true)
        expect(LoadedClass::M).to eq(:m)
        expect(LoadedClass::N).to eq(:n)
      end

      it 'correctly verifies expectations when constant is removed' do
        dbl1 = class_double(LoadedClass::Nested).as_stubbed_const
        class_double(LoadedClass).as_stubbed_const

        prevents {
          expect(dbl1).to receive(:undefined_class_method)
        }
      end

      it 'only allows defined methods for null objects' do
        o = class_double('LoadedClass').as_null_object

        expect(o.defined_class_method).to eq(o)
        prevents { o.undefined_method }
      end

      it 'verifies arguments for null objects' do
        o = class_double('LoadedClass').as_null_object

        expect {
          o.defined_class_method(:too, :many, :args)
        }.to raise_error(ArgumentError, "Wrong number of arguments. Expected 0, got 3.")
      end

      it 'validates `with` args against the method signature when stubbing a method' do
        dbl = class_double(LoadedClass)
        prevents(/Wrong number of arguments. Expected 0, got 2./) {
          allow(dbl).to receive(:defined_class_method).with(2, :args)
        }
      end

      context "when given an anonymous class" do
        it 'properly verifies' do
          subclass = Class.new(LoadedClass)
          o = class_double(subclass)
          allow(o).to receive(:defined_class_method)
          prevents { allow(o).to receive(:undefined_method) }
        end
      end

      context "when given a class that has an overriden `#name` method" do
        it "properly verifies" do
          check_verification class_double(LoadedClassWithOverridenName)
        end

        it "can still stub the const" do
          class_double(LoadedClassWithOverridenName).as_stubbed_const
          check_verification LoadedClassWithOverridenName
        end

        def check_verification(o)
          allow(o).to receive(:defined_class_method)
          prevents { allow(o).to receive(:undefined_method) }
        end
      end

      context "when the class const has been previously stubbed" do
        before { stub_const("LoadedClass", Class.new) }

        it "uses the original class to verify against for `class_double('ClassName')`" do
          o = class_double("LoadedClass")
          allow(o).to receive(:defined_class_method)
          prevents { allow(o).to receive(:undefined_method) }
        end

        it "uses the original class to verify against for `instance_double(ClassName)`" do
          o = class_double(LoadedClass)
          allow(o).to receive(:defined_class_method)
          prevents { allow(o).to receive(:undefined_method) }
        end
      end
    end
  end
end
