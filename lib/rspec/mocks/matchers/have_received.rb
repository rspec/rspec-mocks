module RSpec
  module Mocks
    module Matchers
      # @private
      class HaveReceived
        COUNT_CONSTRAINTS = %w[exactly at_least at_most times once twice thrice]
        ARGS_CONSTRAINTS = %w[with]
        CONSTRAINTS = COUNT_CONSTRAINTS + ARGS_CONSTRAINTS + %w[ordered]

        def initialize(method_name, &block)
          @method_name = method_name
          @block = block
          @constraints = []
          @subject = nil
        end

        def name
          "have_received"
        end

        def matches?(subject, &block)
          @block ||= block
          @subject = subject
          @expectation = expect
          mock_proxy.ensure_implemented(@method_name)

          expected_messages_received_in_order?
        end

        def does_not_match?(subject)
          @subject = subject
          ensure_count_unconstrained
          @expectation = expect.never
          mock_proxy.ensure_implemented(@method_name)
          expected_messages_received_in_order?
        end

        def failure_message
          generate_failure_message
        end

        def failure_message_when_negated
          generate_failure_message
        end

        def description
          (@expectation ||= expect).description_for("have received")
        end

        CONSTRAINTS.each do |expectation|
          define_method expectation do |*args|
            @constraints << [expectation, *args]
            self
          end
        end

        def setup_allowance(_subject, &_block)
          disallow("allow", " as it would have no effect")
        end

        def setup_any_instance_allowance(_subject, &_block)
          disallow("allow_any_instance_of")
        end

        def setup_any_instance_expectation(_subject, &_block)
          disallow("expect_any_instance_of")
        end

      private

        def disallow(type, reason="")
          raise RSpec::Mocks::MockExpectationError,
                "Using #{type}(...) with the `have_received` " \
                "matcher is not supported#{reason}."
        end

        def expect
          expectation = mock_proxy.build_expectation(@method_name)
          apply_constraints_to expectation
          expectation
        end

        def apply_constraints_to(expectation)
          @constraints.each do |constraint|
            expectation.send(*constraint)
          end
        end

        def ensure_count_unconstrained
          return unless count_constraint
          raise RSpec::Mocks::MockExpectationError,
                "can't use #{count_constraint} when negative"
        end

        def count_constraint
          @constraints.map(&:first).find do |constraint|
            COUNT_CONSTRAINTS.include?(constraint)
          end
        end

        def generate_failure_message
          mock_proxy.check_for_unexpected_arguments(@expectation)
          @expectation.generate_error
        rescue RSpec::Mocks::MockExpectationError => error
          error.message
        end

        def expected_messages_received_in_order?
          mock_proxy.replay_received_message_on @expectation, &@block
          @expectation.expected_messages_received? && @expectation.ensure_expected_ordering_received!
        end

        def mock_proxy
          RSpec::Mocks.space.proxy_for(@subject)
        end
      end
    end
  end
end
