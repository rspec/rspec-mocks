require 'rspec/mocks/ruby_features'

module RSpec
  module Mocks

    # Figures out wheter a given method can accept various arguments.
    # Surprisingly non-trivial.
    #
    # @api private
    class MethodSignature
      def initialize(method)
        @method = method
      end

      # @api private
      def accepts?(args)
        non_keyword_args, keyword_args = *classify(args)

        (required_keyword_args - keyword_args).empty? &&
          (keyword_args - allowed_keyword_args).empty? &&
          within_range?(non_keyword_args.length)
      end

      # @api private
      def error_description(actual_args)
        non_keyword_args, keyword_args = *classify(actual_args)

        missing_keyword_args = required_keyword_args - keyword_args
        invalid_keyword_args = keyword_args - allowed_keyword_args

        if missing_keyword_args.any?
          "Missing required keyword arguments: %s" % [
            missing_keyword_args.join(", ")
          ]
        elsif invalid_keyword_args.any?
          "Invalid keyword arguments provided: %s" % [
            invalid_keyword_args.join(", ")
          ]
        else
          "Wrong number of arguments. Expected %s, got %s." % [
            range_description,
            non_keyword_args.length
          ]
        end
      end

      private

      def method
        @method
      end

      def classify(args)
        keyword_args = if allowed_keyword_args.any? && args.last.is_a?(Hash)
          args.pop.keys
        else
          []
        end

        [args, keyword_args]
      end

      def range_description
        if min_non_keyword_args == max_non_keyword_args
          return min_non_keyword_args.to_s
        end

        if max_non_keyword_args == INFINITY
          return "#{min_non_keyword_args} or more"
        end

        "#{min_non_keyword_args} to #{max_non_keyword_args}"
      end

      def within_range?(actual)
        min_non_keyword_args <= actual && actual <= max_non_keyword_args
      end

      if RubyFeatures.required_keyword_args_supported?
        def missing_required_keyword_args(actual_args)
          keyword_args = actual_args.last
          keyword_args = {} unless keyword_args.is_a?(Hash)

          required_keyword_args - keyword_args.keys
        end
      else
        def missing_required_keyword_args(_)
          []
        end
      end

      if RubyFeatures.optional_and_splat_args_supported?
        def min_non_keyword_args
          if method.arity >= 0
            method.arity
          else
            # `~` inverts the one's complement and gives us the number of
            # required arguments.
            ~method.arity
          end
        end

        def max_non_keyword_args
          params = method.parameters
          if params.any? {|(type, _)| type == :rest }
            # Method takes a splat argument
            return INFINITY
          else
            params.count {|(type, _)|
              ![:block, :keyreq, :key].include?(type)
            }
          end
        end
      else
        def min_non_keyword_args
          return method.arity if method.arity >= 0
          # `~` inverts the one's complement and gives us the number of
          # required arguments.
          ~method.arity
        end

        def max_non_keyword_args
          # On 1.8, Method#parameters does not exist.  There is no way to
          # distinguish between default and splat args, so there is no way to
          # have it work correctly for both default and splat args, as far as I
          # can tell. The best we can do is consider it INFINITY (to be
          # tolerant of splat args).
          method.arity < 0 ? INFINITY : method.arity
        end
      end

      if RubyFeatures.required_keyword_args_supported?
        def required_keyword_args
          method.parameters.map {|type, name|
            name if type == :keyreq
          }.compact
        end
      else
        def required_keyword_args
          []
        end
      end

      if RubyFeatures.keyword_args_supported?
        def allowed_keyword_args
          method.parameters.map {|type, name|
            name if [:keyreq, :key].include?(type)
          }.compact
        end

      else
        def allowed_keyword_args
          []
        end
      end

      INFINITY = 1/0.0
    end
  end
end
