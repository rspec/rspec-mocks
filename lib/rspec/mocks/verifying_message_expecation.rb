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
      # Conceptually the method reference makes more sense as a constructor
      # argument since it should be immutable, but it is significantly more
      # straight forward to build the object in pieces so for now it stays as
      # an accessor.
      attr_accessor :method_reference

      def initialize(*args)
        super
      end

      # @override
      def with(*args, &block)
        unless ArgumentMatchers::AnyArgsMatcher === args.first
          expected_arity = if ArgumentMatchers::NoArgsMatcher === args.first
            0
          elsif args.length > 0
            args.length
          else
            # No arguments given, this will raise.
            super
          end

          ensure_arity!(expected_arity)
        end
        super
      end

    private

      def ensure_arity!(actual)
        return if method_reference.nil?

        method_reference.when_defined do |method|
          calculator = ArityCalculator.new(method)
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
end

