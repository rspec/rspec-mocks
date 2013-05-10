module RSpec
  module Mocks
    module AnyInstance
      # @api private
      class ExpectationChain < Chain
        def expectation_fulfilled?
          @expectation_fulfilled || constrained_to_any_of?(:never, :any_number_of_times)
        end

        def initialize(*args, &block)
          @expectation_fulfilled = false
          super
        end

        private
        def verify_invocation_order(rspec_method_name, *args, &block)
        end
      end

      # @api private
      class PositiveExpectationChain < ExpectationChain

        private

        def create_message_expectation_on(instance)
          proxy = ::RSpec::Mocks.proxy_for(instance)
          expected_from = IGNORED_BACKTRACE_LINE
          proxy.add_message_expectation(expected_from, *@expectation_args, &@expectation_block)
        end

        def invocation_order
          @invocation_order ||= {
            :with => [nil],
            :and_return => [:with, nil],
            :and_raise => [:with, nil]
          }
        end
      end

      # @api private
      class NegativeExpectationChain < ExpectationChain
        # `should_not_receive` causes a failure at the point in time the
        # message is wrongly received, rather than during `rspec_verify`
        # at the end of an example. Thus, we should always consider a
        # negative expectation fulfilled for the purposes of end-of-example
        # verification (which is where this is used).
        def expectation_fulfilled?
          true
        end

        private

        def create_message_expectation_on(instance)
          proxy = ::RSpec::Mocks.proxy_for(instance)
          expected_from = IGNORED_BACKTRACE_LINE
          proxy.add_negative_message_expectation(expected_from, *@expectation_args, &@expectation_block)
        end

        def invocation_order
          @invocation_order ||= {
            :with => [nil],
            :and_return => [:with, nil],
            :and_raise => [:with, nil]
          }
        end
      end
    end
  end
end
