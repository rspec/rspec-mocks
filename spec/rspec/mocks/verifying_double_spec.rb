require 'spec_helper'

class LoadedClass
  extend RSpec::Mocks::RubyFeatures

  M = :m
  N = :n
  INSTANCE = LoadedClass.new

  class << self

    def respond_to?(method_name, include_all = false)
      return true if method_name == :dynamic_class_method
      super
    end

    def defined_class_method
    end

    def send
      # fake out!
    end

  protected

    def defined_protected_class_method
    end

  private

    def defined_private_class_method
    end

  end

  def defined_instance_method
  end

  if required_kw_args_supported?
    # Need to eval this since it is invalid syntax on earlier rubies.
    eval <<-RUBY
      def kw_args_method(optional_arg:'hello', required_arg:)
      end
    RUBY
  end

  def send(*)
  end

  def respond_to?(method_name, include_all = false)
    return true if method_name == :dynamic_instance_method
    super
  end

  class Nested; end

protected

  def defined_protected_method
  end

private

  def defined_private_method
    "wink wink ;)"
  end

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

          it 'handles classes that are materialized after mocking' do
            stub_const "A::B", Object.new
            o = instance_double "A", :undefined_instance_method => true

            expect(o.undefined_instance_method).to eq(true)
          end

          context 'for null objects' do
            let(:o) { instance_double('NonLoadedClass').as_null_object }

            it 'returns self from any message' do
              expect(o.a.b.c).to be(o)
            end

            it 'reports it responds to any message' do
              expect(o.respond_to?(:a)).to be true
              expect(o.respond_to?(:a, false)).to be true
              expect(o.respond_to?(:a, true)).to be true
            end
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

          it 'allows `send` to be stubbed if it is defined on the class' do
            o = instance_double('LoadedClass')
            allow(o).to receive(:send).and_return("received")
            expect(o.send(:msg)).to eq("received")
          end

          it 'gives a descriptive error message for NoMethodError' do
            o = instance_double("LoadedClass")
            expect {
              o.defined_private_method
            }.to raise_error(NoMethodError,
                               /Double "LoadedClass \(instance\)"/)
          end

          describe "method visibility" do
            shared_examples_for "preserves method visibility" do |visibility|
              method_name = :"defined_#{visibility}_method"

              it "can allow a #{visibility} instance method" do
                o = instance_double('LoadedClass')
                allow(o).to receive(method_name).and_return(3)
                expect(o.send method_name).to eq(3)
              end

              it "can expect a #{visibility} instance method" do
                o = instance_double('LoadedClass')
                expect(o).to receive(method_name)
                o.send method_name
              end

              it "preserves #{visibility} visibility when allowing a #{visibility} method" do
                preserves_visibility(method_name, visibility) do
                  instance_double('LoadedClass').tap do |o|
                    allow(o).to receive(method_name)
                  end
                end
              end

              it "preserves #{visibility} visibility when expecting a #{visibility} method" do
                preserves_visibility(method_name, visibility) do
                  instance_double('LoadedClass').tap do |o|
                    expect(o).to receive(method_name).at_least(:once)
                    o.send(method_name) # to satisfy the expectation
                  end
                end
              end

              it "preserves #{visibility} visibility on a null object" do
                preserves_visibility(method_name, visibility) do
                  instance_double('LoadedClass').as_null_object
                end
              end
            end

            include_examples "preserves method visibility", :private
            include_examples "preserves method visibility", :protected
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
            }.to raise_error(ArgumentError,
                               "Wrong number of arguments. Expected 0, got 1.")
          end

          if required_kw_args_supported?
            it 'allows keyword arguments' do
              o = instance_double('LoadedClass', :kw_args_method => true)
              expect(o.kw_args_method(:required_arg => 'something')).to eq(true)
            end

            it 'checks that stubbed methods with required keyword args are ' +
               'invoked with the required arguments' do
              o = instance_double('LoadedClass', :kw_args_method => true)
              expect {
                o.kw_args_method(:optional_arg => 'something')
              }.to raise_error(ArgumentError)
            end
          end

          it 'allows class to be specified by constant' do
            o = instance_double(LoadedClass, :defined_instance_method => 1)
            expect(o.defined_instance_method).to eq(1)
          end

          context 'for null objects' do
            let(:o) { instance_double('LoadedClass').as_null_object }

            it 'only allows defined methods' do
              expect(o.defined_instance_method).to eq(o)
              prevents { o.undefined_method }
              prevents { o.send(:undefined_method) }
              prevents { o.__send__(:undefined_method) }
            end

            it 'reports what public messages it responds to accurately' do
              expect(o.respond_to?(:defined_instance_method)).to be true
              expect(o.respond_to?(:defined_instance_method, true)).to be true
              expect(o.respond_to?(:defined_instance_method, false)).to be true

              expect(o.respond_to?(:undefined_method)).to be false
              expect(o.respond_to?(:undefined_method, true)).to be false
              expect(o.respond_to?(:undefined_method, false)).to be false
            end

            it 'reports that it responds to defined private methods when the appropriate arg is passed' do
              expect(o.respond_to?(:defined_private_method)).to be false
              expect(o.respond_to?(:defined_private_method, true)).to be true
              expect(o.respond_to?(:defined_private_method, false)).to be false
            end

            if RUBY_VERSION.to_f < 2.0 # respond_to?(:protected_method) changed behavior in Ruby 2.0.
              it 'reports that it responds to protected methods' do
                expect(o.respond_to?(:defined_protected_method)).to be true
                expect(o.respond_to?(:defined_protected_method, true)).to be true
                expect(o.respond_to?(:defined_protected_method, false)).to be true
              end
            else
              it 'reports that it responds to protected methods when the appropriate arg is passed' do
                expect(o.respond_to?(:defined_protected_method)).to be false
                expect(o.respond_to?(:defined_protected_method, true)).to be true
                expect(o.respond_to?(:defined_protected_method, false)).to be false
              end
            end
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

          it 'gives a descriptive error message for NoMethodError' do
            o = class_double("LoadedClass")
            expect {
              o.defined_private_class_method
            }.to raise_error(NoMethodError, /Double "LoadedClass"/)
          end

          describe "method visibility" do
            shared_examples_for "preserves method visibility" do |visibility|
              method_name = :"defined_#{visibility}_class_method"

              it "can allow a #{visibility} instance method" do
                o = class_double('LoadedClass')
                allow(o).to receive(method_name).and_return(3)
                expect(o.send method_name).to eq(3)
              end

              it "can expect a #{visibility} instance method" do
                o = class_double('LoadedClass')
                expect(o).to receive(method_name)
                o.send method_name
              end

              it "preserves #{visibility} visibility when allowing a #{visibility} method" do
                preserves_visibility(method_name, visibility) do
                  class_double('LoadedClass').tap do |o|
                    allow(o).to receive(method_name)
                  end
                end
              end

              it "preserves #{visibility} visibility when expecting a #{visibility} method" do
                preserves_visibility(method_name, visibility) do
                  class_double('LoadedClass').tap do |o|
                    expect(o).to receive(method_name).at_least(:once)
                    o.send(method_name) # to satisfy the expectation
                  end
                end
              end

              it "preserves #{visibility} visibility on a null object" do
                preserves_visibility(method_name, visibility) do
                  class_double('LoadedClass').as_null_object
                end
              end
            end

            include_examples "preserves method visibility", :private
            include_examples "preserves method visibility", :protected
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
        end

        it 'cannot be constructed with a non-module object' do
          expect {
            class_double(Object.new)
          }.to raise_error(/Module or String expected/)
        end

        it "trying to raise a class_double raises a TypeError", :unless => RUBY_VERSION == '1.9.2' do
          subject = Object.new
          class_double("StubbedError").as_stubbed_const
          allow(subject).to receive(:some_method).and_raise(StubbedError)
          expect { subject.some_method }.to raise_error(TypeError, 'exception class/object expected')
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

      def preserves_visibility(method_name, visibility)
        double = yield

        expect {
          # send bypasses visbility, so we use eval instead.
          eval("double.#{method_name}")
        }.to raise_error(NoMethodError, a_message_indicating_visibility_violation(method_name, visibility))

        expect { double.send(method_name) }.not_to raise_error
        expect { double.__send__(method_name) }.not_to raise_error

        unless double.null_object?
          # Null object doubles use `method_missing` and so the singleton class
          # doesn't know what methods are defined.
          singleton_class = class << double; self; end
          expect(singleton_class.send("#{visibility}_method_defined?", method_name)).to be true
        end
      end

      RSpec::Matchers.define :a_message_indicating_visibility_violation do |method_name, visibility|
        match do |msg|
          # This should NOT Be just `msg.match(visibility)` because the method being called
          # has the visibility name in it. We want to ensure it's a message that ruby is
          # stating is of the given visibility.
          msg.match("#{visibility} ") && msg.match(method_name.to_s)
        end
      end
    end
  end
end
