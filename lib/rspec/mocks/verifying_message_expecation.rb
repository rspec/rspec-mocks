require 'rspec/mocks/arity_calculator'

module RSpec
  module Mocks

    # A message expectation that knows about the real implementation of the
    # message being expected, so that it can verify that any expectations
    # have the correct arity.
    class VerifyingMessageExpectation < MessageExpectation

      # A level of indirection is used here rather than just passing in the
      # method itself, since method look up is expensive and we only want to
      # do it if actually needed.
      #
      # Conceptually the method finder makes more sense as a constructor
      # argument since it should be immutable, but it is significantly more
      # straight forward to build the object in pieces so for now it stays as
      # an accessor.
      attr_accessor :method_finder

      def initialize(*args)
        super
        @method_finder = Proc.new { ArityCalculator::MethodNotLoaded }
      end

      # @override
      def with(*args, &block)
        unless ArgumentMatchers::AnyArgsMatcher === args.first
          expected_arity = if block
            block.arity
          elsif ArgumentMatchers::NoArgsMatcher === args.first
            0
          elsif args.length > 0
            args.length
          else
            raise ArgumentError, "No arguments nor block given."
          end

          ensure_arity!(expected_arity)
        end
        super
      end

    private

      def ensure_arity!(actual)
        calculator = ArityCalculator.new(method_finder.call(message))

        unless calculator.within_range?(actual)
          # Fail fast is required, otherwise the message expecation will fail
          # as well ("expected method not called") and clobber this one.
          @failed_fast = true
          @error_generator.raise_arity_error(calculator, actual)
        end
      end
    end
  end
end

