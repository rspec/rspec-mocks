module RSpec
  module Mocks
    # @private
    # @see RSpec::Mocks::Proxy
    class ReceivedMessage
      attr_reader :name, :args, :block

      def initialize(message_name, method_double, *args, &block)
        @name = message_name
        @method_double = method_double
        @args = args
        @block = block
      end

      def process!(receiving_object, error_generator, is_null_object, has_negative_expectation, messages_arg_list)
        message = @name
        received_message = self
        args = @args
        block = @block
        expectation = received_message.find_matching_expectation
        stub = received_message.find_matching_stub

        if received_message.matching_stub_and_matching_expectation_and_expectation_maxxed? || received_message.only_matching_stub?
          expectation.increase_actual_received_count! if expectation && expectation.actual_received_count_matters?
          if (expectation = find_almost_matching_expectation)
            expectation.advise(*args) unless expectation.expected_messages_received?
          end
          stub.invoke(nil, *args, &block)
        elsif expectation
          expectation.unadvise(messages_arg_list)
          expectation.invoke(stub, *args, &block)
        elsif (expectation = find_almost_matching_expectation)
          expectation.advise(*args) if is_null_object unless expectation.expected_messages_received?

          if is_null_object || !has_negative_expectation.call
            expectation.raise_unexpected_message_args_error([args])
          end
        elsif (stub = find_almost_matching_stub)
          stub.advise(*args)
          error_generator.raise_missing_default_stub_error(stub, [args])
        elsif Class === receiving_object
          receiving_object.superclass.__send__(message, *args, &block)
        else
          receiving_object.__send__(:method_missing, message, *args, &block)
        end
      end

      def find_matching_stub
        @method_double.stubs.find { |stub| stub.matches?(@name, *@args, &@block) }
      end

      def find_matching_expectation
        find_best_matching_expectation do |expectation|
          expectation.matches?(@name, *@args, &@block)
        end
      end

      def find_almost_matching_stub
        @method_double.stubs.find { |stub| stub.matches_name_but_not_args(@name, *@args) }
      end

      def find_almost_matching_expectation
        find_best_matching_expectation do |expectation|
          expectation.matches_name_but_not_args(@name, *@args)
        end
      end

      def matching_stub_and_matching_expectation_and_expectation_maxxed?
        find_matching_stub && find_matching_expectation && find_matching_expectation.called_max_times?
      end

      def only_matching_stub?
        find_matching_stub && !find_matching_expectation
      end

      private
      def find_best_matching_expectation
        first_match = nil

        @method_double.expectations.each do |expectation|
          next unless yield expectation
          return expectation unless expectation.called_max_times?
          first_match ||= expectation
        end

        first_match
      end
    end
  end
end
