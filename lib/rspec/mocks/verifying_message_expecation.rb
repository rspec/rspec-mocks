RSpec::Support.require_rspec_support 'method_signature_verifier'

module RSpec
  module Mocks
    # A message expectation that knows about the real implementation of the
    # message being expected, so that it can verify that any expectations
    # have the valid arguments.
    # @api private
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

      # @private
      def with(*args, &block)
        unless ArgumentMatchers::AnyArgsMatcher === args.first
          expected_args = if ArgumentMatchers::NoArgsMatcher === args.first
                            []
                          elsif args.length > 0
                            args
                          else
                            # No arguments given, this will raise.
                            super
                          end

          validate_expected_arguments!(expected_args)
        end
        super
      end

    private

      def validate_expected_arguments!(actual_args)
        return if method_reference.nil?

        method_reference.with_signature do |signature|
          verifier = Support::LooseSignatureVerifier.new(
            signature,
            actual_args
          )

          unless verifier.valid?
            # Fail fast is required, otherwise the message expecation will fail
            # as well ("expected method not called") and clobber this one.
            @failed_fast = true
            @error_generator.raise_invalid_arguments_error(verifier)
          end
        end
      end
    end
  end
end
