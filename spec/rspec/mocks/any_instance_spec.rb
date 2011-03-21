require 'spec_helper'

module RSpec
  module Mocks
    describe "#any_instance" do
      class CustomErrorForTesting < StandardError;end
      let(:klass) do 
        klass = Class.new
        klass.class_eval{ def ooga;2;end }
        klass
      end
      
      context "invocation order" do
        context "#stub" do
          it "raises an error if 'stub' follows 'with'" do
            lambda{ klass.any_instance.with("1").stub(:foo) }.should raise_error(NoMethodError)
          end
        
          it "raises an error if 'with' follows 'and_return'" do
            lambda{ klass.any_instance.stub(:foo).and_return(1).with("1") }.should raise_error(NoMethodError)
          end
        
          it "raises an error if 'with' follows 'and_raise'" do
            lambda{ klass.any_instance.stub(:foo).and_raise(1).with("1") }.should raise_error(NoMethodError)
          end
          
          it "raises an error if 'with' follows 'and_yield'" do
            lambda{ klass.any_instance.stub(:foo).and_yield(1).with("1") }.should raise_error(NoMethodError)
          end
        end
        
        context "#should_receive" do
          it "raises an error if 'should_receive' follows 'with'" do
            lambda{ klass.any_instance.with("1").should_receive(:foo) }.should raise_error(NoMethodError)
          end
        
          it "raises an error if 'with' follows 'and_return'" do
            pending "see Github issue #42"
            lambda{ klass.any_instance.should_receive(:foo).and_return(1).with("1") }.should raise_error(NoMethodError)
          end
        
          it "raises an error if 'with' follows 'and_raise'" do
            pending "see Github issue #42"
            lambda{ klass.any_instance.should_receive(:foo).and_raise(1).with("1") }.should raise_error(NoMethodError)
          end
        end
      end
      
      context "with #stub" do
        it "should not suppress an exception when a method that doesn't exist is invoked" do
          klass.any_instance.stub(:foo)
          lambda{ klass.new.bar }.should raise_error(NoMethodError)
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
        
        context "with #and_yield" do
          it "yields the value specified" do
            yielded_value = Object.new
            klass.any_instance.stub(:foo).and_yield(yielded_value)
            
            klass.new.foo{|value| value.should be(yielded_value)}
          end
        end

        context "with #and_raise" do
          it "stubs a method that doesn't exist on any instance of a particular class" do
            klass.any_instance.stub(:foo).and_raise(CustomErrorForTesting)
            lambda{ klass.new.foo}.should raise_error(CustomErrorForTesting)
          end

          it "stubs a method that exists on any instance of a particular class" do
            klass.any_instance.stub(:ooga).and_raise(CustomErrorForTesting)
            lambda{ klass.new.ooga}.should raise_error(CustomErrorForTesting)
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
      end
      
      context "with #should_receive" do
        context "when the method on which the expectation is set doesn't exist" do
          it "returns the expected value" do
            klass.any_instance.should_receive(:foo).and_return(1)
            klass.new.foo(1).should == 1
          end
        
          it "fails the verification if an instance is created but no invocation occurs" do
            pending "This test fails as expected, but I'm not sure how to set the *expectation* that it should fail"
            klass.any_instance.should_receive(:foo)
            expect{ klass.new.rspec_verify }.to raise_error(RSpec::Mocks::MockExpectationError)
          end
        
          it "does nothing if no instance is created" do
            klass.any_instance.should_receive(:foo).and_return(1)
          end
        end

        context "when an expectation is set on a method that exists" do
          it "returns the expected value" do
            klass.any_instance.should_receive(:ooga).and_return(1)
            klass.new.ooga(1).should == 1
          end
        
          it "fails the verification if an instance is created but no invocation occurs" do
            pending "This test fails as expected, but I'm not sure how to set the *expectation* that it should fail"
            klass.any_instance.should_receive(:ooga)
            expect{ klass.new.rspec_verify }.to raise_error(RSpec::Mocks::MockExpectationError)
          end
        
          it "does nothing if no instance is created" do
            klass.any_instance.should_receive(:ooga).and_return(1)
          end
        end
      end
      
      context "when resetting after an example" do
        it "restores the class to its original state after each example" do
          space = RSpec::Mocks::Space.new
          space.add(klass)
          
          klass.any_instance.stub(:ooga).and_return(1)
          klass.should be_method_defined(:__ooga_without_any_instance__)
          
          space.reset_all
          
          klass.should_not be_method_defined(:__ooga_without_any_instance__)
          klass.new.ooga.should == 2
        end
      
        it "adds an class to the current space when #any_instance is invoked" do
          klass.any_instance
          RSpec::Mocks::space.send(:mocks).should include(klass)
        end
        
        it "adds an instance to the current space" do
          klass.any_instance.stub(:foo)
          instance = klass.new
          instance.foo
          RSpec::Mocks::space.send(:mocks).should include(instance)
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
