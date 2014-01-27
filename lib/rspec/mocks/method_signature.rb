require 'rspec/mocks/ruby_features'

module RSpec
  module Mocks

    # Figures out wheter a given method can accept various arguments.
    # Surprisingly non-trivial.
    #
    # The concept of arity here is weird, especially when considering keyword
    # arguments. It does not match up with Ruby's `arity` method (which is even
    # weirder). The best intepretation of the methods here is "the min/max
    # valid length of an array representation of the method arguments."
    #
    # Since keyword arguments are represented as a hash at this level, they can
    # only ever add one to the arity, no matter how many there are. A splatted
    # argument will set the maximum arity to infinity.
    #
    # @api private
    class MethodSignature
      def initialize(method)
        @method = method
      end

      # @api private
      def accepts?(actual_args)
        missing_required_keyword_args(actual_args).empty? &&
          within_range?(actual_args.length)
      end

      # @api private
      def error_description(actual_args)
        missing = missing_required_keyword_args(actual_args)
        if missing.empty?
          "Wrong number of arguments. Expected %s, got %s." % [
            range_description,
            actual_args.length
          ]
        else
          "Missing required keyword arguments: %s" % [
            missing.join(", ")
          ]
        end
      end

      private

      def range_description
        return min_arity.to_s if min_arity == max_arity
        return "#{min_arity} or more" if max_arity == INFINITY
        "#{min_arity} to #{max_arity}"
      end

      def within_range?(actual)
        min_arity <= actual && actual <= max_arity
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

      def method
        @method
      end

      if RubyFeatures.optional_and_splat_args_supported?
        def required_keyword_args
          method.parameters.map {|type, name|
            name if type == :keyreq
          }.compact
        end

        def min_arity
          if method.arity >= 0
            method.arity
          else
            # `~` inverts the one's complement and gives us the number of
            # required arguments.
            ~method.arity
          end + parameter_modifier(:keyreq)
        end

        def max_arity
          params = method.parameters
          if params.any? {|(type, _)| type == :rest }
            # Method takes a splat argument
            return INFINITY
          else
            params.count {|(type, _)|
              ![:block, :keyreq, :key].include?(type)
            } + parameter_modifier(:key)
          end
        end
      else
        def required_keyword_args
          []
        end

        def min_arity
          return method.arity if method.arity >= 0
          # `~` inverts the one's complement and gives us the number of
          # required arguments.
          ~method.arity
        end

        def max_arity
          # On 1.8, Method#parameters does not exist.  There is no way to
          # distinguish between default and splat args, so there is no way to
          # have it work correctly for both default and splat args, as far as I
          # can tell. The best we can do is consider it INFINITY (to be
          # tolerant of splat args).
          method.arity < 0 ? INFINITY : method.arity
        end
      end

      def parameter_modifier(parameter_type)
        method.parameters.any? {|type, _|
          type == parameter_type
        } ? 1 : 0
      end

      INFINITY = 1/0.0
    end
  end
end
