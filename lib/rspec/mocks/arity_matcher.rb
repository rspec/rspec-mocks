module RSpec
  module Mocks

    # Responsible for figuring out and communicating what the valid arity range
    # for a method is.
    class ArityMatcher
      attr_reader :method

      def initialize(method)
        @method = method
      end

      # Default value for method if it not available.
      METHOD_NOT_LOADED = Object.new

      class << self
        def match!(method, actual); new(method).match!(actual) end
      end

      def match!(actual)
        unless match?(actual)
          raise RSpec::Expectations::ExpectationNotMetError,
            failure_message_for_arity(actual)
        end
      end

      def match?(actual)
        return true if method == METHOD_NOT_LOADED

        (min_arity..max_arity).cover?(actual)
      end

      def failure_message_for_arity(actual_arity)
        "Wrong number of arguments for %s. Expected %s, got %s." % [
          method.name,
          arity_description,
          actual_arity
        ]
      end

      private

      def min_arity
        return method.arity if method.arity >= 0
        # `~` inverts the one's complement and gives us the number of
        # required arguments.
        ~method.arity
      end

      if method(:method).respond_to?(:parameters)
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

      def arity_description
        return min_arity if min_arity == max_arity
        return "#{min_arity} or more" if max_arity == INFINITY
        "#{min_arity} to #{max_arity}"
      end

      INFINITY = 1/0.0
    end
  end
end

