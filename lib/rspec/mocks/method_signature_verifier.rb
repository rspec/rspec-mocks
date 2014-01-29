require 'rspec/mocks/ruby_features'

module RSpec
  module Mocks

    # Figures out wheter a given method can accept various arguments.
    # Surprisingly non-trivial.
    #
    # @api private
    class MethodSignatureVerifier
      def initialize(method, args)
        @method = method
        @args   = args
      end

      # @api private
      def valid?
         missing_kw_args.empty? &&
          invalid_kw_args.empty? &&
          valid_non_kw_args?
      end

      # @api private
      def error
        if missing_kw_args.any?
          "Missing required keyword arguments: %s" % [
            missing_kw_args.join(", ")
          ]
        elsif invalid_kw_args.any?
          "Invalid keyword arguments provided: %s" % [
            invalid_kw_args.join(", ")
          ]
        elsif !valid_non_kw_args?
          "Wrong number of arguments. Expected %s, got %s." % [
            non_kw_args_error,
            non_kw_args.length
          ]
        end
      end

      private

      def method
        @method
      end

      def valid_non_kw_args?
        actual = non_kw_args.length
        min_non_kw_args <= actual && actual <= max_non_kw_args
      end

      def non_kw_args
        split_args(@args)[0]
      end

      def kw_args
        split_args(@args)[1]
      end

      def missing_kw_args
        required_kw_args - kw_args
      end

      def invalid_kw_args
        kw_args - allowed_kw_args
      end

      def split_args(args)
        @split_args ||= begin
          kw_args = if allowed_kw_args.any? && args.last.is_a?(Hash)
            args.pop.keys
          else
            []
          end

          [args, kw_args]
        end
      end

      def non_kw_args_error
        if min_non_kw_args == max_non_kw_args
          return min_non_kw_args.to_s
        end

        if max_non_kw_args == INFINITY
          return "#{min_non_kw_args} or more"
        end

        "#{min_non_kw_args} to #{max_non_kw_args}"
      end

      if RubyFeatures.optional_and_splat_args_supported?
        def min_non_kw_args
          if method.arity >= 0
            method.arity
          else
            # `~` inverts the one's complement and gives us the number of
            # required arguments.
            ~method.arity
          end
        end

        def max_non_kw_args
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
        def min_non_kw_args
          return method.arity if method.arity >= 0
          # `~` inverts the one's complement and gives us the number of
          # required arguments.
          ~method.arity
        end

        def max_non_kw_args
          # On 1.8, Method#parameters does not exist.  There is no way to
          # distinguish between default and splat args, so there is no way to
          # have it work correctly for both default and splat args, as far as I
          # can tell. The best we can do is consider it INFINITY (to be
          # tolerant of splat args).
          method.arity < 0 ? INFINITY : method.arity
        end
      end

      if RubyFeatures.kw_args_supported?
        def allowed_kw_args
          method.parameters.map {|type, name|
            name if [:keyreq, :key].include?(type)
          }.compact
        end

      else
        def allowed_kw_args
          []
        end
      end

      if RubyFeatures.required_kw_args_supported?
        def required_kw_args
          method.parameters.map {|type, name|
            name if type == :keyreq
          }.compact
        end
      else
        def required_kw_args
          []
        end
      end

      INFINITY = 1/0.0
    end
  end
end
