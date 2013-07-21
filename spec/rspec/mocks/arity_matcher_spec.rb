require 'spec_helper'

module RSpec
  module Mocks
    describe ArityMatcher do
      describe '#match!' do
        def match!(arity)
          described_class.match!(test_method, arity)
        end

        describe 'with unloaded method' do
          let(:test_method) { ArityMatcher::METHOD_NOT_LOADED }

          it 'does not raise for any arity' do
            match!(123)
          end
        end

        describe 'a method with arguments' do
          def arity_two(_, _); end

          let(:test_method) { method(:arity_two) }

          it 'does not raise if given arity is equal' do
              match!(2)
          end

          it 'raises if given arity is less' do
            expect {
              match!(1)
            }.to raise_error(/Expected 2, got 1/i)
          end

          it 'raises if given arity is more' do
            expect {
              match!(3)
            }.to raise_error(/Expected 2, got 3/i)
          end
        end

        describe 'a method with splat arguments' do
          def arity_splat(_, *); end

          let(:test_method) { method(:arity_splat) }

          it 'does not raise for any arity more than requred arguments' do
            match!(123)
          end

          it 'raises for less than required arguments' do
            expect {
              match!(0)
            }.to raise_error(/Expected 1 or more, got 0/i)
          end
        end

        describe 'a method with optional arguments' do
          def arity_optional(_, _, x = 1); end

          let(:test_method) { method(:arity_optional) }

          it 'does not raise if given arity is equal to minimum' do
            match!(2)
          end

          it 'does not raise if given arity is equal to maximum' do
            match!(3)
          end

          it 'raises if given arity is less than minimum' do
            expect {
              match!(1)
            }.to raise_error(/Expected 2 to 3, got 1/i)
          end

          it 'raises if given arity is more than maximum' do
            expect {
              match!(4)
            }.to raise_error(/Expected 2 to 3, got 4/i)
          end
        end

        describe 'a method with a block' do
          def arity_block(_, &block); end

          let(:test_method) { method(:arity_block) }

          it 'does not count the block as a parameter' do
            match!(1)
            expect {
              match!(2)
            }.to raise_error(/Expected 1, got 2/i)
          end
        end
      end
    end
  end
end
