require 'spec_helper'

module RSpec
  module Mocks
    describe ArityCalculator do
      describe '#verify!' do
        subject { described_class.new(test_method) }

        def within_range?(arity)
          subject.within_range?(arity)
        end

        def description
          subject.range_description
        end

        describe 'with a method with arguments' do
          def arity_two(x, y); end

          let(:test_method) { method(:arity_two) }

          it 'covers only the exact arity' do
            expect(within_range?(1)).to eq(false)
            expect(within_range?(2)).to eq(true)
            expect(within_range?(3)).to eq(false)
          end

          it 'is described precisely' do
            expect(description).to eq("2")
          end
        end

        describe 'a method with splat arguments' do
          def arity_splat(_, *); end

          let(:test_method) { method(:arity_splat) }

          it 'covers a range from the lower bound upwards' do
            expect(within_range?(0)).to eq(false)
            expect(within_range?(1)).to eq(true)
            expect(within_range?(2)).to eq(true)
            expect(within_range?(3)).to eq(true)
          end

          it 'is described with no upper bound' do
            expect(description).to eq("1 or more")
          end
        end

        describe 'a method with optional arguments' do
          def arity_optional(x, y, z = 1); end

          let(:test_method) { method(:arity_optional) }

          it 'covers a range from min to max possible arguments' do
            expect(within_range?(1)).to eq(false)
            expect(within_range?(2)).to eq(true)
            expect(within_range?(3)).to eq(true)

            if ArityCalculator.supports_optional_and_splat_args?
              expect(within_range?(4)).to eq(false)
            else
              expect(within_range?(4)).to eq(true)
            end
          end

          if ArityCalculator.supports_optional_and_splat_args?
            it 'is described as a range' do
              expect(description).to eq("2 to 3")
            end
          else
            it 'is described with no upper bound' do
              expect(description).to eq("2 or more")
            end
          end
        end

        describe 'a method with a block' do
          def arity_block(_, &block); end

          let(:test_method) { method(:arity_block) }

          it 'does not count the block as a parameter' do
            expect(within_range?(1)).to eq(true)
            expect(within_range?(2)).to eq(false)
          end

          it 'is described precisely' do
            expect(description).to eq("1")
          end
        end
      end
    end
  end
end
