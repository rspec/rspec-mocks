require 'spec_helper'

TOP_LEVEL_VALUE_CONST = 7

class TestClass
  M = :m
  N = :n

  class Nested
    class NestedEvenMore
    end
  end
end

class TestSubClass < TestClass
  P = :p
end

module RSpec
  module Mocks
    describe "Constant Mutating" do
      include RSpec::Mocks::RecursiveConstMethods

      def reset_rspec_mocks
        ::RSpec::Mocks.space.reset_all
      end

      shared_context "constant example methods" do |const_name|
        define_method :const do
          recursive_const_get(const_name)
        end

        define_method :parent_const do
          recursive_const_get("Object::" + const_name.sub(/(::)?[^:]+\z/, ''))
        end

        define_method :last_const_part do
          const_name.split('::').last
        end
      end

      shared_examples_for "loaded constant stubbing" do |const_name|
        include_context "constant example methods", const_name

        let!(:original_const_value) { const }
        after { change_const_value_to(original_const_value) }

        def change_const_value_to(value)
          parent_const.send(:remove_const, last_const_part)
          parent_const.const_set(last_const_part, value)
        end

        it 'allows it to be stubbed' do
          const.should_not eq(7)
          stub_const(const_name, 7)
          const.should eq(7)
        end

        it 'resets it to its original value when rspec clears its mocks' do
          original_value = const
          original_value.should_not eq(:a)
          stub_const(const_name, :a)
          reset_rspec_mocks
          const.should be(original_value)
        end

        it 'returns the stubbed value' do
          stub_const(const_name, 7).should eq(7)
        end
      end

      shared_examples_for "loaded constant hiding" do |const_name|
        before { recursive_const_defined?(const_name).should be_true }

        it 'allows it to be hidden' do
          hide_const(const_name)
          recursive_const_defined?(const_name).should be_false
        end

        it 'resets the constant when rspec clear its mocks' do
          hide_const(const_name)
          reset_rspec_mocks
          recursive_const_defined?(const_name).should be_true
        end

        it 'returns nil' do
          hide_const(const_name).should be_nil
        end
      end

      shared_examples_for "unloaded constant stubbing" do |const_name|
        include_context "constant example methods", const_name

        before { recursive_const_defined?(const_name).should be_false }

        it 'allows it to be stubbed' do
          stub_const(const_name, 7)
          const.should eq(7)
        end

        it 'removes the constant when rspec clears its mocks' do
          stub_const(const_name, 7)
          reset_rspec_mocks
          recursive_const_defined?(const_name).should be_false
        end

        it 'returns the stubbed value' do
          stub_const(const_name, 7).should eq(7)
        end

        it 'ignores the :transfer_nested_constants option if passed' do
          stub = Module.new
          stub_const(const_name, stub, :transfer_nested_constants => true)
          stub.constants.should eq([])
        end
      end

      shared_examples_for "unloaded constant hiding" do |const_name|
        include_context "constant example methods", const_name

        before { recursive_const_defined?(const_name).should be_false }

        it 'allows it to be hidden, though the operation has no effect' do
          hide_const(const_name)
          recursive_const_defined?(const_name).should be_false
        end

        it 'remains undefined after rspec clears its mocks' do
          hide_const(const_name)
          reset_rspec_mocks
          recursive_const_defined?(const_name).should be_false
        end

        it 'returns nil' do
          hide_const(const_name).should be_nil
        end
      end

      describe "#hide_const" do
        context 'for a loaded nested constant' do
          it_behaves_like "loaded constant hiding", "TestClass::Nested"
        end

        context 'for a loaded context prefixed with ::' do
          it_behaves_like 'loaded constant hiding', "::TestClass"
        end

        context 'for an unloaded constant with nested name that matches a top-level constant' do
          it_behaves_like "unloaded constant hiding", "TestClass::Hash"

          it 'does not hide the top-level constant' do
            top_level_hash = ::Hash

            hide_const("TestClass::Hash")
            expect(::Hash).to equal(top_level_hash)
          end

          it 'does not affect the ability to access the top-level constant from nested contexts', :silence_warnings do
            top_level_hash = ::Hash

            hide_const("TestClass::Hash")
            expect(TestClass::Hash).to equal(top_level_hash)
          end
        end

        context 'for a loaded deeply nested constant' do
          it_behaves_like "loaded constant hiding", "TestClass::Nested::NestedEvenMore"
        end

        context 'for an unloaded unnested constant' do
          it_behaves_like "unloaded constant hiding", "X"
        end

        context 'for an unloaded nested constant' do
          it_behaves_like "unloaded constant hiding", "X::Y"
        end

        it 'can be hidden multiple times but still restores the original value properly' do
          orig_value = TestClass
          hide_const("TestClass")
          hide_const("TestClass")

          reset_rspec_mocks
          TestClass.should be(orig_value)
        end

        it 'allows a constant to be hidden, then stubbed, restoring it to its original value properly' do
          orig_value = TOP_LEVEL_VALUE_CONST

          hide_const("TOP_LEVEL_VALUE_CONST")
          recursive_const_defined?("TOP_LEVEL_VALUE_CONST").should be_false

          stub_const("TOP_LEVEL_VALUE_CONST", 12345)
          TOP_LEVEL_VALUE_CONST.should == 12345

          reset_rspec_mocks
          TOP_LEVEL_VALUE_CONST.should == orig_value
        end
      end

      describe "#stub_const" do
        context 'for a loaded unnested constant' do
          it_behaves_like "loaded constant stubbing", "TestClass"

          it 'can be stubbed multiple times but still restores the original value properly' do
            orig_value = TestClass
            stub1, stub2 = Module.new, Module.new
            stub_const("TestClass", stub1)
            stub_const("TestClass", stub2)

            reset_rspec_mocks
            TestClass.should be(orig_value)
          end

          it 'allows nested constants to be transferred to a stub module' do
            tc_nested = TestClass::Nested
            stub = Module.new
            stub_const("TestClass", stub, :transfer_nested_constants => true)
            stub::M.should eq(:m)
            stub::N.should eq(:n)
            stub::Nested.should be(tc_nested)
          end

          it 'does not transfer nested constants that are inherited from a superclass' do
            stub = Module.new
            stub_const("TestSubClass", stub, :transfer_nested_constants => true)
            stub::P.should eq(:p)
            defined?(stub::M).should be_false
            defined?(stub::N).should be_false
          end

          it 'raises an error when asked to transfer a nested inherited constant' do
            original_tsc = TestSubClass

            expect {
              stub_const("TestSubClass", Module.new, :transfer_nested_constants => [:M])
            }.to raise_error(ArgumentError)

            TestSubClass.should be(original_tsc)
          end

          it 'allows nested constants to be selectively transferred to a stub module' do
            stub = Module.new
            stub_const("TestClass", stub, :transfer_nested_constants => [:M, :N])
            stub::M.should eq(:m)
            stub::N.should eq(:n)
            defined?(stub::Nested).should be_false
          end

          it 'raises an error if asked to transfer nested constants but given an object that does not support them' do
            original_tc = TestClass
            stub = Object.new
            expect {
              stub_const("TestClass", stub, :transfer_nested_constants => true)
            }.to raise_error(ArgumentError)

            TestClass.should be(original_tc)

            expect {
              stub_const("TestClass", stub, :transfer_nested_constants => [:M])
            }.to raise_error(ArgumentError)

            TestClass.should be(original_tc)
          end

          it 'raises an error if asked to transfer nested constants on a constant that does not support nested constants' do
            stub = Module.new
            expect {
              stub_const("TOP_LEVEL_VALUE_CONST", stub, :transfer_nested_constants => true)
            }.to raise_error(ArgumentError)

            TOP_LEVEL_VALUE_CONST.should eq(7)

            expect {
              stub_const("TOP_LEVEL_VALUE_CONST", stub, :transfer_nested_constants => [:M])
            }.to raise_error(ArgumentError)

            TOP_LEVEL_VALUE_CONST.should eq(7)
          end

          it 'raises an error if asked to transfer a nested constant that is not defined' do
            original_tc = TestClass
            defined?(TestClass::V).should be_false
            stub = Module.new

            expect {
              stub_const("TestClass", stub, :transfer_nested_constants => [:V])
            }.to raise_error(/cannot transfer nested constant.*V/i)

            TestClass.should be(original_tc)
          end
        end

        context 'for a loaded nested constant' do
          it_behaves_like "loaded constant stubbing", "TestClass::Nested"
        end

        context 'for a loaded context prefixed with ::' do
          it_behaves_like 'loaded constant stubbing', "::TestClass"
        end

        context 'for an unloaded constant with nested name that matches a top-level constant' do
          it_behaves_like "unloaded constant stubbing", "TestClass::Hash"
        end

        context 'for a loaded deeply nested constant' do
          it_behaves_like "loaded constant stubbing", "TestClass::Nested::NestedEvenMore"
        end

        context 'for an unloaded unnested constant' do
          it_behaves_like "unloaded constant stubbing", "X"
        end

        context 'for an unloaded nested constant' do
          it_behaves_like "unloaded constant stubbing", "X::Y"

          it 'removes the root constant when rspec clears its mocks' do
            defined?(X).should be_false
            stub_const("X::Y", 7)
            reset_rspec_mocks
            defined?(X).should be_false
          end
        end

        context 'for an unloaded deeply nested constant' do
          it_behaves_like "unloaded constant stubbing", "X::Y::Z"

          it 'removes the root constant when rspec clears its mocks' do
            defined?(X).should be_false
            stub_const("X::Y::Z", 7)
            reset_rspec_mocks
            defined?(X).should be_false
          end
        end

        context 'for an unloaded constant nested within a loaded constant' do
          it_behaves_like "unloaded constant stubbing", "TestClass::X"

          it 'removes the unloaded constant but leaves the loaded constant when rspec resets its mocks' do
            defined?(TestClass).should be_true
            defined?(TestClass::X).should be_false
            stub_const("TestClass::X", 7)
            reset_rspec_mocks
            defined?(TestClass).should be_true
            defined?(TestClass::X).should be_false
          end

          it 'raises a helpful error if it cannot be stubbed due to an intermediary constant that is not a module' do
            TestClass::M.should be_a(Symbol)
            expect { stub_const("TestClass::M::X", 5) }.to raise_error(/cannot stub/i)
          end
        end

        context 'for an unloaded constant nested deeply within a deeply nested loaded constant' do
          it_behaves_like "unloaded constant stubbing", "TestClass::Nested::NestedEvenMore::X::Y::Z"

          it 'removes the first unloaded constant but leaves the loaded nested constant when rspec resets its mocks' do
            defined?(TestClass::Nested::NestedEvenMore).should be_true
            defined?(TestClass::Nested::NestedEvenMore::X).should be_false
            stub_const("TestClass::Nested::NestedEvenMore::X::Y::Z", 7)
            reset_rspec_mocks
            defined?(TestClass::Nested::NestedEvenMore).should be_true
            defined?(TestClass::Nested::NestedEvenMore::X).should be_false
          end
        end
      end
    end

    describe Constant do
      describe ".original" do
        context 'for a previously defined unstubbed constant' do
          let(:const) { Constant.original("TestClass::M") }

          it("exposes its name")                    { const.name.should eq("TestClass::M") }
          it("indicates it was previously defined") { const.should be_previously_defined }
          it("indicates it has not been mutated")   { const.should_not be_mutated }
          it("indicates it has not been stubbed")   { const.should_not be_stubbed }
          it("indicates it has not been hidden")    { const.should_not be_hidden }
          it("exposes its original value")          { const.original_value.should eq(:m) }
        end

        context 'for a previously defined stubbed constant' do
          before { stub_const("TestClass::M", :other) }
          let(:const) { Constant.original("TestClass::M") }

          it("exposes its name")                    { const.name.should eq("TestClass::M") }
          it("indicates it was previously defined") { const.should be_previously_defined }
          it("indicates it has been mutated")       { const.should be_mutated }
          it("indicates it has been stubbed")       { const.should be_stubbed }
          it("indicates it has not been hidden")    { const.should_not be_hidden }
          it("exposes its original value")          { const.original_value.should eq(:m) }
        end

        context 'for a previously undefined stubbed constant' do
          before { stub_const("TestClass::Undefined", :other) }
          let(:const) { Constant.original("TestClass::Undefined") }

          it("exposes its name")                        { const.name.should eq("TestClass::Undefined") }
          it("indicates it was not previously defined") { const.should_not be_previously_defined }
          it("indicates it has been mutated")           { const.should be_mutated }
          it("indicates it has been stubbed")           { const.should be_stubbed }
          it("indicates it has not been hidden")        { const.should_not be_hidden }
          it("returns nil for the original value")      { const.original_value.should be_nil }
        end

        context 'for a previously undefined unstubbed constant' do
          let(:const) { Constant.original("TestClass::Undefined") }

          it("exposes its name")                        { const.name.should eq("TestClass::Undefined") }
          it("indicates it was not previously defined") { const.should_not be_previously_defined }
          it("indicates it has not been mutated")       { const.should_not be_mutated }
          it("indicates it has not been stubbed")       { const.should_not be_stubbed }
          it("indicates it has not been hidden")        { const.should_not be_hidden }
          it("returns nil for the original value")      { const.original_value.should be_nil }
        end

        context 'for a previously defined constant that has been stubbed twice' do
          before { stub_const("TestClass::M", 1) }
          before { stub_const("TestClass::M", 2) }
          let(:const) { Constant.original("TestClass::M") }

          it("exposes its name")                    { const.name.should eq("TestClass::M") }
          it("indicates it was previously defined") { const.should be_previously_defined }
          it("indicates it has been mutated")       { const.should be_mutated }
          it("indicates it has been stubbed")       { const.should be_stubbed }
          it("indicates it has not been hidden")    { const.should_not be_hidden }
          it("exposes its original value")          { const.original_value.should eq(:m) }
        end

        context 'for a previously undefined constant that has been stubbed twice' do
          before { stub_const("TestClass::Undefined", 1) }
          before { stub_const("TestClass::Undefined", 2) }
          let(:const) { Constant.original("TestClass::Undefined") }

          it("exposes its name")                        { const.name.should eq("TestClass::Undefined") }
          it("indicates it was not previously defined") { const.should_not be_previously_defined }
          it("indicates it has been mutated")           { const.should be_mutated }
          it("indicates it has been stubbed")           { const.should be_stubbed }
          it("indicates it has not been hidden")        { const.should_not be_hidden }
          it("returns nil for the original value")      { const.original_value.should be_nil }
        end

        context 'for a previously defined hidden constant' do
          before { hide_const("TestClass::M") }
          let(:const) { Constant.original("TestClass::M") }

          it("exposes its name")                    { const.name.should eq("TestClass::M") }
          it("indicates it was previously defined") { const.should be_previously_defined }
          it("indicates it has been mutated")       { const.should be_mutated }
          it("indicates it has not been stubbed")   { const.should_not be_stubbed }
          it("indicates it has been hidden")        { const.should be_hidden }
          it("exposes its original value")          { const.original_value.should eq(:m) }
        end

        context 'for a previously defined constant that has been hidden twice' do
          before { hide_const("TestClass::M") }
          before { hide_const("TestClass::M") }
          let(:const) { Constant.original("TestClass::M") }

          it("exposes its name")                    { const.name.should eq("TestClass::M") }
          it("indicates it was previously defined") { const.should be_previously_defined }
          it("indicates it has been mutated")       { const.should be_mutated }
          it("indicates it has not been stubbed")   { const.should_not be_stubbed }
          it("indicates it has been hidden")        { const.should be_hidden }
          it("exposes its original value")          { const.original_value.should eq(:m) }
        end
      end
    end
  end
end

