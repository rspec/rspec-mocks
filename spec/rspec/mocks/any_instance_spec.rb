require 'spec_helper'

module RSpec
  module Mocks
    describe "#any_instance" do
      let(:klass) { Class.new }
      
      it "should raise an error if the method chain is in the wrong order" do
        pending
        lambda{ klass.any_instance.with("1").stub(:foo) }.should raise_error(NoMethodError)
      end
      
      context "with #stub" do
        it "should not suppress an exception when a method that doesn't exist is invoked" do
          pending
          klass.any_instance.stub(:foo)
          lambda{ klass.new.bar }.should raise_error(NoMethodError)
        end
      end
      
      context "with #and_return" do
        it "stubs a method on any instance of a particular class" do
          pending
          klass.any_instance.stub(:foo).and_return(1)
          klass.new.foo.should == 1
        end

        it "returns the same object for calls on different instances" do
          pending
          return_value = Object.new
          klass.any_instance.stub(:foo).and_return(return_value)
          klass.new.foo.should be(return_value)
          klass.new.foo.should be(return_value)
        end
      end
      
      context "with a block" do
        it "stubs a method on any instance of a particular class" do
          pending
          klass.any_instance.stub(:foo) { 1 }
          klass.new.foo.should == 1
        end

        it "returns the same computed value for calls on different instances" do
          pending
          klass.any_instance.stub(:foo) { 1 + 2 }
          klass.new.foo.should == klass.new.foo
        end
      end
      
      context "when resetting after an example" do
        it "restores the class to its original state after each example" do
          pending
          space = RSpec::Mocks::Space.new
          space.add(klass)
          klass.any_instance.stub(:foo).and_return(1)
          space.reset_all
          lambda{ klass.new.foo }.should raise_error(NoMethodError)
          klass.should_not respond_to(:__new_without_any_instance__)
        end
      
        it "adds a class to the current space when #any_instance is invoked" do
          pending
          klass.any_instance
          RSpec::Mocks::space.send(:mocks).should include(klass)
        end
      end
      
      context "ensuring core ruby objects aren't clobbered" do
        it "should work uniformly across *everything*" do
          pending
          Object.any_instance.stub(:foo).and_return(1)
          Object.new.foo.should == 1
        end
        
        it "should work with the non-standard constructor []" do
          pending
          Array.any_instance.stub(:foo).and_return(1)
          [].foo.should == 1
        end
        
        it "should work with the non-standard constructor {}" do
          pending
          Hash.any_instance.stub(:foo).and_return(1)
          {}.foo.should == 1
        end
        
        it "should work with the non-standard constructor \"\"" do
          pending
          String.any_instance.stub(:foo).and_return(1)
          "".foo.should == 1
        end
        
        it "should work with the non-standard constructor \'\'" do
          pending
          String.any_instance.stub(:foo).and_return(1)
          ''.foo.should == 1
        end

        it "should work with the non-standard constructor module" do
          pending
          Module.any_instance.stub(:foo).and_return(1)
          module RSpec::SampleRspecTestModule;end
          RSpec::SampleRspecTestModule.foo.should == 1
        end
        
        it "should work with the non-standard constructor class" do
          pending
          Class.any_instance.stub(:foo).and_return(1)
          class RSpec::SampleRspecTestClass;end
          RSpec::SampleRspecTestClass.foo.should == 1
        end
      end
    end
  end
end