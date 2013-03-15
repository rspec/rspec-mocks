module RSpec
  module Mocks
    class HaveReceived
      CONSTRAINTS = %w(
        exactly at_least at_most times any_number_of_times once twice with
      )

      def initialize(method_name)
        @method_name = method_name
        @constraints = []
      end

      def matches?(subject)
        @expectation = expect(subject)
        @expectation.expected_messages_received?
      end

      def does_not_match?(subject)
        @expectation = expect(subject).never
        @expectation.expected_messages_received?
      end

      def failure_message
        generate_failure_message
      end

      def negative_failure_message
        generate_failure_message
      end

      CONSTRAINTS.each do |expectation|
        define_method expectation do |*args|
          @constraints << [expectation, *args]
          self
        end
      end

      private

      def expect(subject)
        subject.__mock_expectation(@method_name) do |expectation|
          apply_constraints_to expectation
        end
      end

      def apply_constraints_to(expectation)
        @constraints.each do |constraint|
          expectation.send(*constraint)
        end
      end

      def generate_failure_message
        @expectation.generate_error
      rescue RSpec::Mocks::MockExpectationError => error
        error.message
      end
    end
  end
end
