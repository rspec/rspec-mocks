require 'spec_helper'

module RSpec
  module Mocks
    describe "#any_instance" do
      let(:klass) do 
        klass = Class.new
        klass.class_eval{ def ooga;2;end }
        klass
      end
      
      it "should raise an error if the method chain is in the wrong order" do
        lambda{ klass.any_instance.with("1").stub(:foo) }.should raise_error(NoMethodError)
      end
      
      context "with #stub" do
        it "should not suppress an exception when a method that doesn't exist is invoked" do
          klass.any_instance.stub(:foo)
          lambda{ klass.new.bar }.should raise_error(NoMethodError)
        end
      end
      
      context "with #and_return" do
        it "stubs a method that doesn't exist on any instance of a particular class" do
          klass.any_instance.stub(:foo).and_return(1)
          klass.new.foo.should == 1
        end

        it "stubs a method that exists on any instance of a particular class" do
          klass.any_instance.stub(:ooga).and_return(1)
          klass.new.ooga.should == 1
        end

        it "returns the same object for calls on different instances" do
          return_value = Object.new
          klass.any_instance.stub(:foo).and_return(return_value)
          klass.new.foo.should be(return_value)
          klass.new.foo.should be(return_value)
        end
      end
      
      context "with a block" do
        it "stubs a method on any instance of a particular class" do
          klass.any_instance.stub(:foo) { 1 }
          klass.new.foo.should == 1
        end

        it "returns the same computed value for calls on different instances" do
          klass.any_instance.stub(:foo) { 1 + 2 }
          klass.new.foo.should == klass.new.foo
        end
      end
      
      context "when resetting after an example" do
        it "restores the class to its original state after each example" do
          space = RSpec::Mocks::Space.new
          space.add(klass)
          klass.any_instance.stub(:foo).and_return(1)
          space.reset_all
          lambda{ klass.new.foo }.should raise_error(NoMethodError)
          klass.should_not respond_to(:__new_without_any_instance__)
        end
      
        it "adds a class to the current space when #any_instance is invoked" do
          klass.any_instance
          RSpec::Mocks::space.send(:mocks).should include(klass)
        end
      end
      
      context "core ruby objects" do
        it "should work uniformly across *everything*" do
          Object.any_instance.stub(:foo).and_return(1)
          Object.new.foo.should == 1
        end
        
        it "should work with the non-standard constructor []" do
          Array.any_instance.stub(:foo).and_return(1)
          [].foo.should == 1
        end
        
        it "should work with the non-standard constructor {}" do
          Hash.any_instance.stub(:foo).and_return(1)
          {}.foo.should == 1
        end
        
        it "should work with the non-standard constructor \"\"" do
          String.any_instance.stub(:foo).and_return(1)
          "".foo.should == 1
        end
        
        it "should work with the non-standard constructor \'\'" do
          String.any_instance.stub(:foo).and_return(1)
          ''.foo.should == 1
        end

        it "should work with the non-standard constructor module" do
          Module.any_instance.stub(:foo).and_return(1)
          module RSpec::SampleRspecTestModule;end
          RSpec::SampleRspecTestModule.foo.should == 1
        end
        
        it "should work with the non-standard constructor class" do
          Class.any_instance.stub(:foo).and_return(1)
          class RSpec::SampleRspecTestClass;end
          RSpec::SampleRspecTestClass.foo.should == 1
        end
      end
    end
  end
end