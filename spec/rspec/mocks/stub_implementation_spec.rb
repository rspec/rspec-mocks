require 'spec_helper'

module RSpec
  module Mocks
    describe "stub implementation" do
      describe "with no args" do
        it "execs the block when called" do
          obj = double()
          obj.stub(:foo) { :bar }
          expect(obj.foo).to eq :bar
        end
      end

      describe "with one arg" do
        it "execs the block with that arg when called" do
          obj = double()
          obj.stub(:foo) {|given| given}
          expect(obj.foo(:bar)).to eq :bar
        end
      end

      describe "with variable args" do
        it "execs the block when called" do
          obj = double()
          obj.stub(:foo) {|*given| given.first}
          expect(obj.foo(:bar)).to eq :bar
        end
      end

      it 'works with proxies that erroneously copied from other objects' do
        obj1 = Object.new
        obj1.stub(:foo).and_return('foo')
        obj2 = Object.new
        obj2.instance_variable_set('@mock_proxy', obj1.instance_variable_get('@mock_proxy'))
        obj2.stub(:bar).and_return('bar')
        expect(obj2.bar).to eq('bar')
      end
    end


    describe "unstub implementation" do
      it "replaces the stubbed method with the original method" do
        obj = Object.new
        def obj.foo; :original; end
        obj.stub(:foo)
        obj.unstub(:foo)
        expect(obj.foo).to eq :original
      end

      it "removes all stubs with the supplied method name" do
        obj = Object.new
        def obj.foo; :original; end
        obj.stub(:foo).with(1)
        obj.stub(:foo).with(2)
        obj.unstub(:foo)
        expect(obj.foo).to eq :original
      end

      it "does not remove any expectations with the same method name" do
        obj = Object.new
        def obj.foo; :original; end
        obj.should_receive(:foo).with(3).and_return(:three)
        obj.stub(:foo).with(1)
        obj.stub(:foo).with(2)
        obj.unstub(:foo)
        expect(obj.foo(3)).to eq :three
      end

      it "restores the correct implementations when stubbed and unstubbed on a parent and child class" do
        parent = Class.new
        child  = Class.new(parent)

        parent.stub(:new)
        child.stub(:new)
        parent.unstub(:new)
        child.unstub(:new)

        expect(parent.new).to be_an_instance_of parent
        expect(child.new).to be_an_instance_of child
      end

      it "raises a MockExpectationError if the method has not been stubbed" do
        obj = Object.new
        expect {
          obj.unstub(:foo)
        }.to raise_error(RSpec::Mocks::MockExpectationError)
      end
    end
  end
end
