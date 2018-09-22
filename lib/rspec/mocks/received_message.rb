module RSpec
  module Mocks
    # @private
    class ReceivedMessage
      def initialize(message_name, method_double, args = [], block = -> {})
        @message_name = message_name
        @method_double = method_double
        @args = args || []
        @block = block || -> {}
        @matching_stub = nil
        @matching_expectation = nil
      end

      def find_matching_stub
        @matching_stub ||= @method_double.stubs.find { |stub| stub.matches?(@message_name, *@args) }
      end

      def find_matching_expectation
        @matching_expectation ||= find_best_matching_expectation do |expectation|
          expectation.matches?(@message_name, *@args)
        end
      end

      def find_almost_matching_stub
        @method_double.stubs.find { |stub| stub.matches_name_but_not_args(@message_name, *@args) }
      end

      def find_almost_matching_expectation
        find_best_matching_expectation do |expectation|
          expectation.matches_name_but_not_args(@message_name, *@args)
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