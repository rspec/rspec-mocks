module RSpec
  module Mocks
    # Raised when a message expectation is not satisfied.
    MockExpectationError = Class.new(Exception)

    # Raised when a test double is used after it has been torn
    # down (typically at the end of an rspec-core example).
    ExpiredTestDoubleError = Class.new(MockExpectationError)

    # Raised when doubles or partial doubles are used outside of the per-test lifecycle.
    OutsideOfExampleError = Class.new(StandardError)

    # Raised when an expectation customization method (e.g. `with`,
    # `and_return`) is called on a message expectation which has already been
    # invoked.
    MockExpectationAlreadyInvokedError = Class.new(Exception)

    # Raised for situations that RSpec cannot support due to mutations made
    # externally on arguments that RSpec is holding onto to use for later
    # comparisons.
    CannotSupportArgMutationsError = Class.new(StandardError)

    # @private
    UnsupportedMatcherError  = Class.new(StandardError)
    # @private
    NegationUnsupportedError = Class.new(StandardError)
    # @private
    VerifyingDoubleNotDefinedError = Class.new(StandardError)

    # @private
    class ErrorGenerator
      attr_writer :opts

      def initialize(target, name)
        @target = target
        @name = name
      end

      # @private
      def opts
        @opts ||= {}
      end

      # @private
      def raise_unexpected_message_error(message, *args)
        __raise "#{intro} received unexpected message :#{message}#{arg_message(*args)}"
      end

      # @private
      def raise_unexpected_message_args_error(expectation, *args)
        expected_args = format_args(*expectation.expected_args)
        actual_args = format_received_args(*args)
        diff = diff_message(expectation.expected_args, args)

        message = default_error_message(expectation, expected_args, actual_args)
        message << "\nDiff:#{diff}" unless diff.empty?

        __raise message
      end

      # @private
      def raise_missing_default_stub_error(expectation, *args)
        expected_args = format_args(*expectation.expected_args)
        actual_args = format_received_args(*args)
        diff = diff_message(expectation.expected_args, args)

        message = default_error_message(expectation, expected_args, actual_args)
        message << "\nDiff:\n #{diff}" unless diff.empty?
        message << "\n Please stub a default value first if message might be received with other args as well. \n"

        __raise message
      end

      # @private
      def raise_similar_message_args_error(expectation, *args_for_multiple_calls)
        expected_args = format_args(*expectation.expected_args)
        actual_args = args_for_multiple_calls.map { |a| format_received_args(*a) }.join(", ")

        __raise(default_error_message(expectation, expected_args, actual_args))
      end

      def default_error_message(expectation, expected_args, actual_args)
        [
          intro,
          "received",
          expectation.message.inspect,
          unexpected_arguments_message(expected_args, actual_args),
        ].join(" ")
      end

      # rubocop:disable Style/ParameterLists
      # @private
      def raise_expectation_error(message, expected_received_count, argument_list_matcher, actual_received_count, expectation_count_type, *args)
        expected_part = expected_part_of_expectation_error(expected_received_count, expectation_count_type, argument_list_matcher)
        received_part = received_part_of_expectation_error(actual_received_count, *args)
        __raise "(#{intro}).#{message}#{format_args(*args)}\n    #{expected_part}\n    #{received_part}"
      end
      # rubocop:enable Style/ParameterLists

      # @private
      def raise_unimplemented_error(doubled_module, method_name)
        __raise "%s does not implement: %s" % [
          doubled_module.description,
          method_name
        ]
      end

      # @private
      def raise_non_public_error(method_name, visibility)
        raise NoMethodError, "%s method `%s' called on %s" % [
          visibility, method_name, intro
        ]
      end

      # @private
      def raise_invalid_arguments_error(verifier)
        __raise verifier.error_message
      end

      # @private
      def raise_expired_test_double_error
        raise ExpiredTestDoubleError,
              "#{intro} was originally created in one example but has leaked into " \
              "another example and can no longer be used. rspec-mocks' doubles are " \
              "designed to only last for one example, and you need to create a new " \
              "one in each example you wish to use it for."
      end

      # @private
      def received_part_of_expectation_error(actual_received_count, *args)
        "received: #{count_message(actual_received_count)}" +
          actual_method_call_args_description(actual_received_count, args)
      end

      # @private
      def expected_part_of_expectation_error(expected_received_count, expectation_count_type, argument_list_matcher)
        "expected: #{count_message(expected_received_count, expectation_count_type)}" +
          expected_method_call_args_description(argument_list_matcher.expected_args)
      end

      # @private
      def actual_method_call_args_description(count, args)
        method_call_args_description(args) ||
          if count > 0 && args.length > 0
            " with arguments: #{args.inspect.gsub(/\A\[(.+)\]\z/, '(\1)')}"
          else
            ""
          end
      end

      # @private
      def expected_method_call_args_description(args)
        method_call_args_description(args) ||
          if args.length > 0
            " with arguments: #{format_args(*args)}"
          else
            ""
          end
      end

      # @private
      def method_call_args_description(args)
        case args.first
        when ArgumentMatchers::AnyArgsMatcher then " with any arguments"
        when ArgumentMatchers::NoArgsMatcher  then " with no arguments"
        end
      end

      # @private
      def describe_expectation(verb, message, expected_received_count, _actual_received_count, *args)
        "#{verb} #{message}#{format_args(*args)} #{count_message(expected_received_count)}"
      end

      # @private
      def raise_out_of_order_error(message)
        __raise "#{intro} received :#{message} out of order"
      end

      # @private
      def raise_block_failed_error(message, detail)
        __raise "#{intro} received :#{message} but passed block failed with: #{detail}"
      end

      # @private
      def raise_missing_block_error(args_to_yield)
        __raise "#{intro} asked to yield |#{arg_list(*args_to_yield)}| but no block was passed"
      end

      # @private
      def raise_wrong_arity_error(args_to_yield, signature)
        __raise "#{intro} yielded |#{arg_list(*args_to_yield)}| to block with #{signature.description}"
      end

      # @private
      def raise_only_valid_on_a_partial_double(method)
        __raise "#{intro} is a pure test double. `#{method}` is only " \
                "available on a partial double."
      end

      # @private
      def raise_expectation_on_unstubbed_method(method)
        __raise "#{intro} expected to have received #{method}, but that " \
                "object is not a spy or method has not been stubbed."
      end

      # @private
      def raise_expectation_on_mocked_method(method)
        __raise "#{intro} expected to have received #{method}, but that " \
                "method has been mocked instead of stubbed or spied."
      end

      def self.raise_double_negation_error(wrapped_expression)
        raise "Isn't life confusing enough? You've already set a " \
              "negative message expectation and now you are trying to " \
              "negate it again with `never`. What does an expression like " \
              "`#{wrapped_expression}.not_to receive(:msg).never` even mean?"
      end

    private

      def unexpected_arguments_message(expected_args_string, actual_args_string)
        "with unexpected arguments\n  expected: #{expected_args_string}\n       got: #{actual_args_string}"
      end

      def diff_message(expected_args, actual_args)
        formatted_expected_args = expected_args.map do |x|
          RSpec::Support.rspec_description_for_object(x)
        end

        formatted_expected_args, actual_args = unpack_string_args(formatted_expected_args, actual_args)

        differ.diff(actual_args, formatted_expected_args)
      end

      def unpack_string_args(formatted_expected_args, actual_args)
        if [formatted_expected_args, actual_args].all? { |x| list_of_exactly_one_string?(x) }
          [formatted_expected_args.first, actual_args.first]
        else
          [formatted_expected_args, actual_args]
        end
      end

      def list_of_exactly_one_string?(args)
        Array === args && args.count == 1 && String === args.first
      end

      def differ
        RSpec::Support::Differ.new(:color => RSpec::Mocks.configuration.color?)
      end

      def intro
        if @name
          "Double #{@name.inspect}"
        elsif TestDouble === @target
          "Double"
        elsif Class === @target
          "<#{@target.inspect} (class)>"
        elsif @target
          @target
        else
          "nil"
        end
      end

      def __raise(message)
        message = opts[:message] unless opts[:message].nil?
        Kernel.raise(RSpec::Mocks::MockExpectationError, message)
      end

      def arg_message(*args)
        " with " + format_args(*args)
      end

      def format_args(*args)
        args.empty? ? "(no args)" : "(" + arg_list(*args) + ")"
      end

      def arg_list(*args)
        args.map { |arg| arg_has_valid_description?(arg) ? arg.description : arg.inspect }.join(", ")
      end

      def arg_has_valid_description?(arg)
        RSpec::Support.is_a_matcher?(arg) && arg.respond_to?(:description)
      end

      def format_received_args(*args)
        args.empty? ? "(no args)" : "(" + received_arg_list(*args) + ")"
      end

      def received_arg_list(*args)
        args.map(&:inspect).join(", ")
      end

      def count_message(count, expectation_count_type=nil)
        return "at least #{times(count.abs)}" if count < 0 || expectation_count_type == :at_least
        return "at most #{times(count)}" if expectation_count_type == :at_most
        times(count)
      end

      def times(count)
        "#{count} time#{count == 1 ? '' : 's'}"
      end
    end
  end
end
