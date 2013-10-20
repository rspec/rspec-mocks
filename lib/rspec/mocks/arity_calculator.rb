module RSpec
  module Mocks

    # Figures out the valid arity range for a method. Surprisingly non-trivial.
    class ArityCalculator

      def initialize(method)
        @method = method
      end

      # @api private
      def within_range?(actual)
        min_arity <= actual && actual <= max_arity
      end

      # @api private
      def range_description
        return min_arity.to_s if min_arity == max_arity
        return "#{min_arity} or more" if max_arity == INFINITY
        "#{min_arity} to #{max_arity}"
      end

      private

      def method
        @method
      end

      # @api private
      def self.supports_optional_and_splat_args?
        Method.method_defined?(:parameters)
      end

      def min_arity
        return method.arity if method.arity >= 0
        # `~` inverts the one's complement and gives us the number of
        # required arguments.
        ~method.arity
      end

      if supports_optional_and_splat_args?
        def max_arity
          params = method.parameters
          if params.any? {|(type, _)| type == :rest }
            # Method takes a splat argument
            return INFINITY
          else
            params.count {|(type, _)| type != :block }
          end
        end
      else
        def max_arity
          # On 1.8, Method#parameters does not exist.  There is no way to
          # distinguish between default and splat args, so there is no way to
          # have it work correctly for both default and splat args, as far as I
          # can tell. The best we can do is consider it INFINITY (to be
          # tolerant of splat args).
          method.arity < 0 ? INFINITY : method.arity
        end
      end

      INFINITY = 1/0.0
    end
  end
end

