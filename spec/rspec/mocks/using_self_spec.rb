require 'spec_helper'

module RSpec
  module Mocks
    describe MessageExpectation do
      before(:each) { @double = double("test double") }
      after(:each)  { @double.rspec_reset }

      let(:klass) do
        Class.new do
          def existing_method; :existing_method_return_value; end
          def existing_method_with_arguments(arg_one, arg_two = nil); :existing_method_with_arguments_return_value; end
          def another_existing_method; end
          private
          def private_method; :private_method_return_value; end
        end
      end

      it "passes double object context to implementation when calling #using_self" do
        @double.stub(:foo).using_self { self }

        expect(@double.foo).to eq @double
      end

      it "still receives all arguments when calling #using_self" do
        @double.stub(:foo).using_self do |foo, *bar|
          [self, foo, bar]
        end

        expect(@double.foo("bar", "baz")) == [@double, "bar", ["baz"]]
      end

      it "allows for passing no block to #using_self" do

        @double.stub(:foo){ self }.using_self

        expect(@double.foo).to eq @double
      end

      it "works when using #any_instance and #using_self together" do
        klass.any_instance.stub(:foo) {
          [self, 1]
        }.using_self
        klass.any_instance.stub(:bar).using_self {
          [self, 2]
        }

        foo_class = klass.new
        bar_class = klass.new

        expect(foo_class.foo).to eq([foo_class, 1])
        expect(bar_class.bar).to eq([bar_class, 2])
      end
    end
  end
end
