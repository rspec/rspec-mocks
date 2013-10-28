require 'spec_helper'

class LoadedClass
  M = :m
  N = :n
  INSTANCE = LoadedClass.new

  def defined_instance_method; end
  def self.defined_class_method; end

  def respond_to?(method_name)
    return true if method_name == :dynamic_instance_method
    super
  end

  def self.respond_to?(method_name)
    return true if method_name == :dynamic_class_method
    super
  end

  def self.send
    # fake out!
  end

  class Nested; end
end

module RSpec
  module Mocks
    describe 'verifying doubles' do
      describe 'instance doubles' do
        describe 'when doubled class is not loaded' do
          include_context "with isolated configuration"

          before do
            RSpec::Mocks.configuration.verify_doubled_constant_names = false
          end

          it 'allows any instance method to be stubbed' do
            o = instance_double('NonloadedClass')
            o.stub(:undefined_instance_method).with(:arg).and_return(true)
            expect(o.undefined_instance_method(:arg)).to eq(true)
          end

          it 'allows any instance method to be expected' do
            o = instance_double("NonloadedClass")

            expect(o).to receive(:undefined_instance_method).
                           with(:arg).
                           and_return(true)

            expect(o.undefined_instance_method(:arg)).to eq(true)
          end
        end

        describe 'when doubled class is loaded' do
          include_context "with isolated configuration"

          before do
            RSpec::Mocks.configuration.verify_doubled_constant_names = true
          end

          it 'only allows instance methods that exist to be stubbed' do
            o = instance_double('LoadedClass', :defined_instance_method => 1)
            expect(o.defined_instance_method).to eq(1)

            prevents { o.stub(:undefined_instance_method) }
            prevents { o.stub(:defined_class_method) }
          end

          it 'only allows instance methods that exist to be expected' do
            o = instance_double('LoadedClass')
            expect(o).to receive(:defined_instance_method)
            o.defined_instance_method

            prevents { expect(o).to receive(:undefined_instance_method) }
            prevents { expect(o).to receive(:defined_class_method) }
            prevents { o.should_receive(:undefined_instance_method) }
            prevents { o.should_receive(:defined_class_method) }
          end

          it 'does not allow dynamic methods to be expected' do
            # This isn't possible at the moment since an instance of the class
            # would be required for the verification, and we only have the
            # class itself.
            #
            # This spec exists as "negative" documentation of the absence of a
            # feature, to highlight the asymmetry from class doubles (that do
            # support this behaviour).
            prevents {
              instance_double('LoadedClass', :dynamic_instance_method => 1)
            }
          end

          it 'checks the arity of stubbed methods' do
            o = instance_double('LoadedClass')
            prevents {
              expect(o).to receive(:defined_instance_method).with(:a)
            }
          end

          it 'checks that stubbed methods are invoked with the correct arity' do
            o = instance_double('LoadedClass', :defined_instance_method => 25)
            expect {
              o.defined_instance_method(:a)
            }.to raise_error(ArgumentError)
          end

          it 'allows class to be specified by constant' do
            o = instance_double(LoadedClass, :defined_instance_method => 1)
            expect(o.defined_instance_method).to eq(1)
          end

          it 'only allows defined methods for null objects' do
            o = instance_double('LoadedClass').as_null_object

            expect(o.defined_instance_method).to eq(o)
            prevents { o.undefined_method }
          end
        end

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
        describe 'when doubled class is not loaded' do
          include_context "with isolated configuration"

          before do
            RSpec::Mocks.configuration.verify_doubled_constant_names = false
          end

          it 'allows any method to be stubbed' do
            o = class_double('NonloadedClass')
            allow(o).to receive(:undefined_instance_method).with(:arg).and_return(1)
            expect(o.undefined_instance_method(:arg)).to eq(1)
          end
        end

        describe 'when doubled class is loaded' do
          include_context "with isolated configuration"

          before do
            RSpec::Mocks.configuration.verify_doubled_constant_names = true
          end

          it 'only allows class methods that exist to be stubbed' do
            o = class_double('LoadedClass', :defined_class_method => 1)
            expect(o.defined_class_method).to eq(1)

            prevents { o.stub(:undefined_instance_method) }
            prevents { o.stub(:defined_instance_method) }
          end

          it 'only allows class methods that exist to be expected' do
            o = class_double('LoadedClass')
            expect(o).to receive(:defined_class_method)
            o.defined_class_method

            prevents { expect(o).to receive(:undefined_instance_method) }
            prevents { expect(o).to receive(:defined_instance_method) }
            prevents { o.should_receive(:undefined_instance_method) }
            prevents { o.should_receive(:defined_instance_method) }
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
            ::RSpec::Mocks.space.reset_all
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
        end

        it 'cannot be constructed with a non-module object' do
          expect {
            class_double(Object.new)
          }.to raise_error(/Module or String expected/)
        end
      end

      describe 'object doubles' do
        it 'replaces an unloaded constant' do
          o = object_double("LoadedClass::NOINSTANCE").as_stubbed_const

          expect(LoadedClass::NOINSTANCE).to eq(o)

          expect(o).to receive(:undefined_instance_method)
          o.undefined_instance_method
        end

        it 'replaces a constant by name and verifies instances methods' do
          o = object_double("LoadedClass::INSTANCE").as_stubbed_const

          expect(LoadedClass::INSTANCE).to eq(o)

          prevents { expect(o).to receive(:undefined_instance_method) }
          prevents { expect(o).to receive(:defined_class_method) }
          prevents { o.defined_instance_method }

          expect(o).to receive(:defined_instance_method)
          o.defined_instance_method
        end

        it 'can create a double that matches the interface of any arbitrary object' do
          o = object_double(LoadedClass.new)

          prevents { expect(o).to receive(:undefined_instance_method) }
          prevents { expect(o).to receive(:defined_class_method) }
          prevents { o.defined_instance_method }

          expect(o).to receive(:defined_instance_method)
          o.defined_instance_method
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
      end


      describe 'when verify_doubled_constant_names config option is set' do
        include_context "with isolated configuration"

        before do
          RSpec::Mocks.configuration.verify_doubled_constant_names = true
        end

        it 'prevents creation of instance doubles for unloaded constants' do
          expect {
            instance_double('LoadedClas')
          }.to raise_error(NameError)
        end

        it 'prevents creation of class doubles for unloaded constants' do
          expect {
            class_double('LoadedClas')
          }.to raise_error(NameError)
        end
      end

      it 'can only be named with a string or a module' do
        expect { instance_double(1) }.to raise_error(ArgumentError)
        expect { instance_double(nil) }.to raise_error(ArgumentError)
      end
    end
  end
end
