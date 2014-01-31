require 'spec_helper'

module RSpec
  module Mocks
    describe MethodSignatureVerifier do
      describe '#verify!' do
        let(:signature) { MethodSignature.new(test_method) }

        def valid_non_kw_args?(arity)
          described_class.new(signature, [nil] * arity).valid?
        end

        def valid?(*args)
          described_class.new(signature, args).valid?
        end

        def error_description
          described_class.new(signature, []).error_message[/Expected (.*),/, 1]
        end

        def error_for(*args)
          described_class.new(signature, args).error_message
        end

        def signature_description
          signature.description
        end

        describe 'with a method with arguments' do
          def arity_two(x, y); end

          let(:test_method) { method(:arity_two) }

          it 'covers only the exact arity' do
            expect(valid_non_kw_args?(1)).to eq(false)
            expect(valid_non_kw_args?(2)).to eq(true)
            expect(valid_non_kw_args?(3)).to eq(false)
          end

          it 'does not treat a last-arg hash as kw args' do
            expect(valid?(1, {})).to eq(true)
          end

          it 'describes the arity precisely' do
            expect(error_description).to eq("2")
          end

          it 'mentions only the arity in the description' do
            expect(signature_description).to eq("arity of 2")
          end
        end

        describe 'a method with splat arguments' do
          def arity_splat(_, *); end

          let(:test_method) { method(:arity_splat) }

          it 'covers a range from the lower bound upwards' do
            expect(valid_non_kw_args?(0)).to eq(false)
            expect(valid_non_kw_args?(1)).to eq(true)
            expect(valid_non_kw_args?(2)).to eq(true)
            expect(valid_non_kw_args?(3)).to eq(true)
          end

          it 'describes the arity with no upper bound' do
            expect(error_description).to eq("1 or more")
          end

          it 'mentions only the arity in the description' do
            expect(signature_description).to eq("arity of 1 or more")
          end
        end

        describe 'a method with optional arguments' do
          def arity_optional(x, y, z = 1); end

          let(:test_method) { method(:arity_optional) }

          it 'covers a range from min to max possible arguments' do
            expect(valid_non_kw_args?(1)).to eq(false)
            expect(valid_non_kw_args?(2)).to eq(true)
            expect(valid_non_kw_args?(3)).to eq(true)

            if optional_and_splat_args_supported?
              expect(valid_non_kw_args?(4)).to eq(false)
            else
              expect(valid_non_kw_args?(4)).to eq(true)
            end
          end

          if optional_and_splat_args_supported?
            it 'describes the arity as a range' do
              expect(error_description).to eq("2 to 3")
            end
          else
            it 'describes the arity with no upper bound' do
              expect(error_description).to eq("2 or more")
            end
          end
        end

        if kw_args_supported?
          describe 'a method with optional keyword arguments' do
            eval <<-RUBY
              def arity_kw(x, y:1, z:2); end
            RUBY

            let(:test_method) { method(:arity_kw) }

            it 'does not require any of the arguments' do
              expect(valid?(nil)).to eq(true)
              expect(valid?(nil, nil)).to eq(false)
            end

            it 'does not allow an invalid keyword arguments' do
              expect(valid?(nil, :a => 1)).to eq(false)
            end

            it 'mentions the invalid keyword args in the error' do
              expect(error_for(nil, :a => 0, :b => 1)).to \
                eq("Invalid keyword arguments provided: a, b")
            end

            it 'describes invalid arity precisely' do
              expect(error_for()).to \
                eq("Wrong number of arguments. Expected 1, got 0.")
            end

            it 'does not blow up when given a BasicObject as the last arg' do
              expect(valid?(BasicObject.new)).to eq(true)
            end

            it 'does not mutate the provided args array' do
              args = [nil, { :y => 1 }]
              described_class.new(signature, args).valid?
              expect(args).to eq([nil, { :y => 1 }])
            end

            it 'mentions the arity and optional kw args in the description' do
              expect(signature_description).to eq("arity of 1 and optional keyword args (:y, :z)")
            end
          end
        end

        if required_kw_args_supported?
          describe 'a method with required keyword arguments' do
            eval <<-RUBY
              def arity_required_kw(x, y:, z:, a: 'default'); end
            RUBY

            let(:test_method) { method(:arity_required_kw) }

            it 'returns false unless all required keywords args are present' do
              expect(valid?(nil, :a => 0, :y => 1, :z => 2)).to eq(true)
              expect(valid?(nil, :a => 0, :y => 1)).to eq(false)
              expect(valid?(nil, nil, :a => 0, :y => 1, :z => 2)).to eq(false)
              expect(valid?(nil, nil)).to eq(false)
            end

            it 'mentions the missing required keyword args in the error' do
              expect(error_for(nil, :a => 0)).to \
                eq("Missing required keyword arguments: y, z")
            end

            it 'is described precisely when arity is wrong' do
              expect(error_for(nil, nil, :z => 0, :y => 1)).to \
                eq("Wrong number of arguments. Expected 1, got 2.")
            end

            it 'mentions the arity, optional kw args and required kw args in the description' do
              expect(signature_description).to \
                eq("arity of 1 and optional keyword args (:a) and required keyword args (:y, :z)")
            end
          end

          describe 'a method with required keyword arguments and a splat' do
            eval <<-RUBY
              def arity_required_kw_splat(w, *x, y:, z:, a: 'default'); end
            RUBY

            let(:test_method) { method(:arity_required_kw_splat) }

            it 'returns false unless all required keywords args are present' do
              expect(valid?(nil, :a => 0, :y => 1, :z => 2)).to eq(true)
              expect(valid?(nil, :a => 0, :y => 1)).to eq(false)
              expect(valid?(nil, nil, :a => 0, :y => 1, :z => 2)).to eq(true)
              expect(valid?(nil, nil, nil)).to eq(false)
              expect(valid?).to eq(false)
            end

            it 'mentions missing required keyword args in the error' do
              expect(error_for(nil, :y => 1)).to \
                eq("Missing required keyword arguments: z")
            end

            it 'mentions the arity, optional kw args and required kw args in the description' do
              expect(signature_description).to \
                eq("arity of 1 or more and optional keyword args (:a) and required keyword args (:y, :z)")
            end
          end

          describe 'a method with required keyword arguments and a keyword arg splat' do
            eval <<-RUBY
              def arity_kw_arg_splat(x:, **rest); end
            RUBY

            let(:test_method) { method(:arity_kw_arg_splat) }

            it 'allows extra undeclared keyword args' do
              expect(valid?(:x => 1)).to eq(true)
              expect(valid?(:x => 1, :y => 2)).to eq(true)
            end

            it 'mentions missing required keyword args in the error' do
              expect(error_for(:y => 1)).to \
                eq("Missing required keyword arguments: x")
            end

            it 'mentions the required kw args and keyword splat in the description' do
              expect(signature_description).to \
                eq("required keyword args (:x) and any additional keyword args")
            end
          end

          describe 'a method with a required arg and a keyword arg splat' do
            eval <<-RUBY
              def arity_kw_arg_splat(x, **rest); end
            RUBY

            let(:test_method) { method(:arity_kw_arg_splat) }

            it 'allows a single arg and any number of keyword args' do
              expect(valid?(nil)).to eq(true)
              expect(valid?(nil, :x => 1)).to eq(true)
              expect(valid?(nil, :x => 1, :y => 2)).to eq(true)
              expect(valid?(:x => 1)).to eq(true)

              expect(valid?).to eq(false)
              expect(valid?(nil, nil)).to eq(false)
              expect(valid?(nil, nil, :x => 1)).to eq(false)
            end

            it 'describes the arity precisely' do
              expect(error_for()).to \
                eq("Wrong number of arguments. Expected 1, got 0.")
            end

            it 'mentions the required kw args and keyword splat in the description' do
              expect(signature_description).to \
                eq("arity of 1 and any additional keyword args")
            end
          end
        end

        describe 'a method with a block' do
          def arity_block(_, &block); end

          let(:test_method) { method(:arity_block) }

          it 'does not count the block as a parameter' do
            expect(valid_non_kw_args?(1)).to eq(true)
            expect(valid_non_kw_args?(2)).to eq(false)
          end

          it 'describes the arity precisely' do
            expect(error_description).to eq("1")
          end
        end
      end
    end
  end
end
