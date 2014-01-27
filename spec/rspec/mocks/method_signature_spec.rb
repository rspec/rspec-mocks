require 'spec_helper'

module RSpec
  module Mocks
    describe MethodSignature do
      describe '#verify!' do
        subject { described_class.new(test_method) }

        def within_range?(arity)
          subject.accepts?([nil] * arity)
        end

        def accepts?(args)
          subject.accepts?(args)
        end

        def description
          subject.error_description([])[/Expected (.*),/, 1]
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

            if optional_and_splat_args_supported?
              expect(within_range?(4)).to eq(false)
            else
              expect(within_range?(4)).to eq(true)
            end
          end

          if optional_and_splat_args_supported?
            it 'is described as a range' do
              expect(description).to eq("2 to 3")
            end
          else
            it 'is described with no upper bound' do
              expect(description).to eq("2 or more")
            end
          end
        end

        if keyword_args_supported?
          describe 'a method with optional keyword arguments' do
            eval <<-RUBY
              def arity_kw(x, y:1, z:2); end
            RUBY

            let(:test_method) { method(:arity_kw) }

            it 'returns false unless all required keywords args are present' do
              expect(within_range?(1)).to eq(true)
              expect(within_range?(2)).to eq(true)
              expect(within_range?(3)).to eq(false)
            end
          end
        end

        if required_keyword_args_supported?
          describe 'a method with required keyword arguments' do
            eval <<-RUBY
              def arity_required_kw(x, y:, z:, a: 'default'); end
            RUBY

            let(:test_method) { method(:arity_required_kw) }

            it 'returns false unless all required keywords args are present' do
              expect(accepts?([nil, {:a => 0, :y => 1, :z => 2}])).to eq(true)
              expect(accepts?([nil, {:a => 0, :y => 1}])).to eq(false)
              expect(accepts?([nil, nil, {:a => 0, :y => 1, :z => 2}])).to eq(false)
              expect(accepts?([nil, nil])).to eq(false)
            end

            it 'is described precisely' do
              expect(subject.error_description([nil, {:a => 0}])).to \
                eq("Missing required keyword arguments: y, z")
            end

            it 'is described precisely when arity is wrong' do
              expect(subject.error_description([{:z => 0, :y => 1}])).to \
                eq("Wrong number of arguments. Expected 2, got 1.")
            end
          end

          describe 'a method with required keyword arguments and a splat' do
            eval <<-RUBY
              def arity_required_kw_splat(w, *x, y:, z:, a: 'default'); end
            RUBY

            let(:test_method) { method(:arity_required_kw_splat) }

            it 'returns false unless all required keywords args are present' do
              expect(accepts?([nil, {:a => 0, :y => 1, :z => 2}])).to eq(true)
              expect(accepts?([nil, {:a => 0, :y => 1}])).to eq(false)
              expect(accepts?([nil, nil, {:a => 0, :y => 1, :z => 2}])).to eq(true)
              expect(accepts?([nil, nil, nil])).to eq(false)
              expect(accepts?([])).to eq(false)
            end

            it 'is described precisely' do
              expect(subject.error_description([nil, {:y => 1}])).to \
                eq("Missing required keyword arguments: z")
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
