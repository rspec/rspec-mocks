module RSpec
  module Mocks
    # @private
    class OrderGroup
      def initialize
        @expectations = []
        @invocation_order = []
        @index = 0
      end

      # @private
      def register(expectation)
        @expectations << expectation
      end

      def invoked(object, message)
        @invocation_order << [object, message]
      end

      # @private
      def ready_for?(expectation)
        remaining_expectations.find(&:ordered?) == expectation
      end

      # @private
      def consume
        remaining_expectations.each_with_index do |expectation, index|
          if expectation.ordered?
            @index += index + 1
            return expectation
          end
        end
        nil
      end

      # @private
      def handle_order_constraint(expectation)
        return unless expectation.ordered? && @expectations.include?(expectation)
        return consume if ready_for?(expectation)
        expectation.raise_out_of_order_error
      end

      def clear
        @index = 0
        @invocation_order.clear
        @expectations.clear
      end

      def empty?
        @expectations.empty?
      end

    private

      def remaining_expectations
        @expectations[@index..-1] || []
      end

    end
  end
end
