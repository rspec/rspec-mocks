module RSpec
  module Mocks
    class HaveReceived
      COUNT_CONSTRAINTS = %w(exactly at_least at_most times once twice)
      ARGS_CONSTRAINTS = %w(with)
      CONSTRAINTS = COUNT_CONSTRAINTS + ARGS_CONSTRAINTS

      def initialize(method_name)
        @method_name = method_name
        @constraints = []
      end

      def matches?(subject)
        @expectation = expect(subject)
        @expectation.expected_messages_received?
      end

      def does_not_match?(subject)
        ensure_count_unconstrained
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
        build_expectation(subject) do |expectation|
          apply_constraints_to expectation
        end
      end

      def apply_constraints_to(expectation)
        @constraints.each do |constraint|
          expectation.send(*constraint)
        end
      end

      def ensure_count_unconstrained
        if count_constrait
          raise RSpec::Mocks::MockExpectationError,
            "can't use #{count_constrait} when negative"
        end
      end

      def count_constrait
        @constraints.map(&:first).detect do |constraint|
          COUNT_CONSTRAINTS.include?(constraint)
        end
      end

      def generate_failure_message
        @expectation.generate_error
      rescue RSpec::Mocks::MockExpectationError => error
        error.message
      end

      def build_expectation(subject, &block)
        subject.__send__(:__mock_proxy).
          build_expectation(@method_name, &block)
      end
    end
  end
end
