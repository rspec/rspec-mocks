module RSpec
  module Mocks
    RSpec.describe "A partial double" do
      let(:object) { Object.new }

      it 'does not create an any_instance recorder when a message is allowed' do
        expect {
          allow(object).to receive(:foo)
        }.not_to change { RSpec::Mocks.space.any_instance_recorders }.from({})
      end

      it "names the class in the failure message" do
        expect(object).to receive(:foo)
        expect do
          verify object
        end.to raise_error(RSpec::Mocks::MockExpectationError, /\(#<Object:.*>\).foo/)
      end

      it "names the class in the failure message when expectation is on class" do
        expect(Object).to receive(:foo)
        expect {
          verify Object
        }.to raise_error(RSpec::Mocks::MockExpectationError, /<Object \(class\)>/)
      end

      it "does not conflict with @options in the object" do
        object.instance_exec { @options = Object.new }
        expect(object).to receive(:blah)
        object.blah
      end

      it 'allows `class` to be stubbed even when `any_instance` has already been used' do
        # See https://github.com/rspec/rspec-mocks/issues/687
        # The infinite recursion code path was only triggered when there were
        # active any instance recorders in the current example, so we make one here.
        allow_any_instance_of(Object).to receive(:bar).and_return(2)

        expect(object.class).not_to eq(String)
        allow(object).to receive_messages(:foo => 1, :class => String)

        expect(object.foo).to eq(1)
        expect(object.class).to eq(String)
        expect(object.bar).to eq(2)
      end

      it "can disallow messages from being received" do
        expect(object).not_to receive(:fuhbar)
        expect {
          object.fuhbar
        }.to raise_error(
          RSpec::Mocks::MockExpectationError,
          /expected\: 0 times with any arguments\n    received\: 1 time/
        )
      end

      it "can expect a message and set a return value" do
        expect(object).to receive(:foobar).with(:test_param).and_return(1)
        expect(object.foobar(:test_param)).to equal(1)
      end

      it "can accept a hash as a message argument" do
        expect(object).to receive(:foobar).with(:key => "value").and_return(1)
        expect(object.foobar(:key => "value")).to equal(1)
      end

      it "can accept an inner hash as a message argument" do
        hash = {:a => {:key => "value"}}
        expect(object).to receive(:foobar).with(:key => "value").and_return(1)
        expect(object.foobar(hash[:a])).to equal(1)
      end

      it "can create a positive message expectation" do
        expect(expect(object).to receive(:foobar)).not_to be_negative
        object.foobar
      end

      it "verifies the method was called when expecting a message" do
        expect(object).to receive(:foobar).with(:test_param).and_return(1)
        expect {
          verify object
        }.to raise_error(RSpec::Mocks::MockExpectationError)
      end

      it "can accept the string form of a message for a positive message expectation" do
        expect(object).to receive('foobar')
        object.foobar
      end

      it "can accept the string form of a message for a negative message expectation" do
        expect(object).not_to receive('foobar')
        expect {
          object.foobar
        }.to raise_error(RSpec::Mocks::MockExpectationError)
      end

      it "uses reports nil in the error message" do
        allow_message_expectations_on_nil

        _nil = nil
        expect(_nil).to receive(:foobar)
        expect {
          verify _nil
        }.to raise_error(
          RSpec::Mocks::MockExpectationError,
          %Q|(nil).foobar(*(any args))\n    expected: 1 time with any arguments\n    received: 0 times with any arguments|
        )
      end

      it "includes the class name in the error when mocking a class method that is called an extra time with the wrong args" do
        klass = Class.new do
          def self.inspect
            "MyClass"
          end
        end

        expect(klass).to receive(:bar).with(1)
        klass.bar(1)

        expect {
          klass.bar(2)
        }.to raise_error(RSpec::Mocks::MockExpectationError, /MyClass/)
      end

      it "shares message expectations with clone" do
        expect(object).to receive(:foobar)
        twin = object.clone
        twin.foobar
        expect{ verify twin }.not_to raise_error
        expect{ verify object }.not_to raise_error
      end

      it "clears message expectations when `dup`ed" do
        expect(object).to receive(:foobar)
        duplicate = object.dup
        expect{ duplicate.foobar }.to raise_error(NoMethodError, /foobar/)
        expect{ verify object }.to raise_error(RSpec::Mocks::MockExpectationError, /foobar/)
      end
    end

    RSpec.describe "Using a partial mock on a proxy object", :if => defined?(::BasicObject) do
      let(:proxy_class) do
        Class.new(::BasicObject) do
          def initialize(target)
            @target = target
          end

          def proxied?
            true
          end

          def respond_to?(name, include_all=false)
            super || name == :proxied? || @target.respond_to?(name, include_all)
          end

          def method_missing(*a)
            @target.send(*a)
          end
        end
      end

      let(:wrapped_object) { Object.new }
      let(:proxy) { proxy_class.new(wrapped_object) }

      it 'works properly' do
        expect(proxy).to receive(:proxied?).and_return(false)
        expect(proxy).not_to be_proxied
      end

      it 'does not confuse the proxy and the proxied object' do
        allow(proxy).to receive(:foo).and_return(:proxy_foo)
        allow(wrapped_object).to receive(:foo).and_return(:wrapped_foo)

        expect(proxy.foo).to eq(:proxy_foo)
        expect(wrapped_object.foo).to eq(:wrapped_foo)
      end
    end

    RSpec.describe "Partially mocking an object that defines ==, after another mock has been defined" do
      before(:each) do
        double("existing mock", :foo => :foo)
      end

      let(:klass) do
        Class.new do
          attr_reader :val
          def initialize(val)
            @val = val
          end

          def ==(other)
            @val == other.val
          end
        end
      end

      it "does not raise an error when stubbing the object" do
        o = klass.new :foo
        expect { allow(o).to receive(:bar) }.not_to raise_error
      end
    end

    RSpec.describe "A partial class mock that has been subclassed" do

      let(:klass)  { Class.new }
      let(:subklass) { Class.new(klass) }

      it "cleans up stubs during #reset to prevent leakage onto subclasses between examples" do
        allow(klass).to receive(:new).and_return(:new_foo)
        expect(subklass.new).to eq :new_foo

        reset(klass)

        expect(subklass.new).to be_a(subklass)
      end

      describe "stubbing a base class class method" do
        before do
          allow(klass).to receive(:find).and_return "stubbed_value"
        end

        it "returns the value for the stub on the base class" do
          expect(klass.find).to eq "stubbed_value"
        end

        it "returns the value for the descendent class" do
          expect(subklass.find).to eq "stubbed_value"
        end
      end
    end

    RSpec.describe "Method visibility when using partial mocks" do
      let(:klass) do
        Class.new do
          def public_method
            private_method
            protected_method
          end
          protected
          def protected_method; end
          private
          def private_method; end
        end
      end

      let(:object) { klass.new }

      it 'keeps public methods public' do
        expect(object).to receive(:public_method)
        expect(object.public_methods).to include_method(:public_method)
        object.public_method
      end

      it 'keeps private methods private' do
        expect(object).to receive(:private_method)
        expect(object.private_methods).to include_method(:private_method)
        object.public_method
      end

      it 'keeps protected methods protected' do
        expect(object).to receive(:protected_method)
        expect(object.protected_methods).to include_method(:protected_method)
        object.public_method
      end

    end

    RSpec.describe 'when verify_partial_doubles configuration option is set' do
      include_context "with isolated configuration"

      let(:klass) do
        Class.new do
          def implemented
            "works"
          end

          def respond_to?(method_name, include_all=false)
            method_name.to_s == "dynamic_method" || super
          end

          def method_missing(method_name, *args)
            if respond_to?(method_name)
              method_name
            else
              super
            end
          end

          private

          def defined_private_method
            "works"
          end
        end
      end

      let(:object) { klass.new }

      before do
        RSpec::Mocks.configuration.verify_partial_doubles = true
      end

      it 'allows valid methods to be expected' do
        expect(object).to receive(:implemented).and_call_original
        expect(object.implemented).to eq("works")
      end

      it 'allows private methods to be expected' do
        expect(object).to receive(:defined_private_method).and_call_original
        expect(object.send(:defined_private_method)).to eq("works")
      end

      it 'does not allow a non-existing method to be expected' do
        prevents { expect(object).to receive(:unimplemented) }
      end

      it 'does not allow a spy on unimplemented method' do
        prevents(/does not implement/) {
          expect(object).to have_received(:unimplemented)
        }
      end

      it 'verifies arity range when matching arguments' do
        prevents { expect(object).to receive(:implemented).with('bogus') }
      end

      it 'allows a method defined with method_missing to be expected' do
        expect(object).to receive(:dynamic_method).with('a').and_call_original
        expect(object.dynamic_method('a')).to eq(:dynamic_method)
      end

      it 'allows valid methods to be expected on any_instance' do
        expect_any_instance_of(klass).to receive(:implemented)
        object.implemented
      end

      it 'allows private methods to be expected on any_instance' do
        expect_any_instance_of(klass).to receive(:defined_private_method).and_call_original
        object.send(:defined_private_method)
      end

      it 'does not allow a non-existing method to be called on any_instance' do
        prevents(/does not implement/) {
          expect_any_instance_of(klass).to receive(:unimplemented)
        }
      end

      it 'does not allow missing methods to be called on any_instance' do
        # This is potentially surprising behaviour, but there is no way for us
        # to know that this method is valid since we only have class and not an
        # instance.
        prevents(/does not implement/) {
          expect_any_instance_of(klass).to receive(:dynamic_method)
        }
      end

      it 'verifies arity range when receiving a message' do
        allow(object).to receive(:implemented)
        expect {
          object.implemented('bogus')
        }.to raise_error(
          ArgumentError,
          a_string_including("Wrong number of arguments. Expected 0, got 1.")
        )
      end

      it 'allows the mock to raise an error with yield' do
        sample_error = Class.new(StandardError)
        expect(object).to receive(:implemented) { raise sample_error }
        expect { object.implemented }.to raise_error(sample_error)
      end

      it 'allows stubbing and calls the stubbed implementation' do
        allow(object).to receive(:implemented) { :value }
        expect(object.implemented).to eq(:value)
      end

    end
  end
end
