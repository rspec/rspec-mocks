require 'rspec/mocks/ruby_features'

module RSpec
  module Mocks
    # Extracts info about the number of arguments and allowed/required
    # keyword args of a given method.
    #
    # @api private
    class MethodSignature
      attr_reader :min_non_kw_args, :max_non_kw_args

      def initialize(method)
        @method = method
        classify_parameters
      end

      def non_kw_args_arity_description
        case max_non_kw_args
          when min_non_kw_args then min_non_kw_args.to_s
          when INFINITY then "#{min_non_kw_args} or more"
          else "#{min_non_kw_args} to #{max_non_kw_args}"
        end
      end

      if RubyFeatures.optional_and_splat_args_supported?
        def description
          @description ||= begin
            parts = []

            unless non_kw_args_arity_description == "0"
              parts << "arity of #{non_kw_args_arity_description}"
            end

            if @optional_kw_args.any?
              parts << "optional keyword args (#{@optional_kw_args.map(&:inspect).join(", ")})"
            end

            if @required_kw_args.any?
              parts << "required keyword args (#{@required_kw_args.map(&:inspect).join(", ")})"
            end

            if @allows_any_kw_args
              parts << "any additional keyword args"
            end

            parts.join(" and ")
          end
        end

        def missing_kw_args_from(given_kw_args)
          @required_kw_args - given_kw_args
        end

        def invalid_kw_args_from(given_kw_args)
          return [] if @allows_any_kw_args
          given_kw_args - @allowed_kw_args
        end

        def has_kw_args_in?(args)
          return false unless Hash === args.last
          return false if args.count <= min_non_kw_args

          @allows_any_kw_args || @allowed_kw_args.any?
        end

        def classify_parameters
          optional_non_kw_args = @min_non_kw_args = 0
          @optional_kw_args, @required_kw_args = [], []
          @allows_any_kw_args = false

          @method.parameters.each do |(type, name)|
            case type
              # def foo(a:)
              when :keyreq  then @required_kw_args << name
              # def foo(a: 1)
              when :key     then @optional_kw_args << name
              # def foo(**kw_args)
              when :keyrest then @allows_any_kw_args = true
              # def foo(a)
              when :req     then @min_non_kw_args += 1
              # def foo(a = 1)
              when :opt     then optional_non_kw_args += 1
              # def foo(*a)
              when :rest    then optional_non_kw_args = INFINITY
            end
          end

          @max_non_kw_args = @min_non_kw_args  + optional_non_kw_args
          @allowed_kw_args = @required_kw_args + @optional_kw_args
        end
      else
        def description
          "arity of #{non_kw_args_arity_description}"
        end

        def missing_kw_args_from(given_kw_args)
          []
        end

        def invalid_kw_args_from(given_kw_args)
          []
        end

        def has_kw_args_in?(args)
          false
        end

        def classify_parameters
          arity = @method.arity
          if arity < 0
            # `~` inverts the one's complement and gives us the
            # number of required args
            @min_non_kw_args = ~arity
            @max_non_kw_args = INFINITY
          else
            @min_non_kw_args = arity
            @max_non_kw_args = arity
          end
        end
      end

      INFINITY = 1/0.0
    end

    # Deals with the slightly different semantics of block arguments.
    # For methods, arguments are required unless a default value is provided.
    # For blocks, arguments are optional, even if no default value is provided.
    #
    # However, we want to treat block args as required since you virtually always
    # want to pass a value for each received argument and our `and_yield` has
    # treated block args as required for many years.
    #
    # @api private
    class BlockSignature < MethodSignature
      if RubyFeatures.optional_and_splat_args_supported?
        def classify_parameters
          super
          @min_non_kw_args = @max_non_kw_args unless @max_non_kw_args == INFINITY
        end
      end
    end

    # Figures out wheter a given method can accept various arguments.
    # Surprisingly non-trivial.
    #
    # @api private
    class MethodSignatureVerifier
      # @api private
      attr_reader :non_kw_args, :kw_args

      def initialize(signature, args)
        @signature = signature
        @non_kw_args, @kw_args = split_args(*args)
      end

      # @api private
      def valid?
         missing_kw_args.empty? &&
          invalid_kw_args.empty? &&
          valid_non_kw_args?
      end

      # @api private
      def error_message
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
            @signature.non_kw_args_arity_description,
            non_kw_args.length
          ]
        end
      end

    private

      def valid_non_kw_args?
        actual = non_kw_args.length
        @signature.min_non_kw_args <= actual && actual <= @signature.max_non_kw_args
      end

      def missing_kw_args
        @signature.missing_kw_args_from(kw_args)
      end

      def invalid_kw_args
        @signature.invalid_kw_args_from(kw_args)
      end

      def split_args(*args)
        kw_args = if @signature.has_kw_args_in?(args)
          args.pop.keys
        else
          []
        end

        [args, kw_args]
      end
    end
  end
end
