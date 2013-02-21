module RSpec
  module Mocks
    module AnyInstance
      # @api private
      class ExpectationChain < Chain
        def expectation_fulfilled?
          @expectation_fulfilled || constrained_to_any_of?(:never, :any_number_of_times)
        end

        def initialize(*args, &block)
          record(*args, &block)
          @expectation_fulfilled = false
        end

        private
        def verify_invocation_order(rspec_method_name, *args, &block)
        end
      end

      # @api private
      class PositiveExpectationChain < ExpectationChain
        def initialize(*args, &block)
          super(:should_receive, *args, &block)
        end

        private

        def invocation_order
          @invocation_order ||= {
            :should_receive => [nil],
            :with => [:should_receive],
            :and_return => [:with, :should_receive],
            :and_raise => [:with, :should_receive]
          }
        end
      end

      # @api private
      class NegativeExpectationChain < ExpectationChain
        def initialize(*args, &block)
          super(:should_not_receive, *args, &block)
        end

        # `should_not_receive` causes a failure at the point in time the
        # message is wrongly received, rather than during `rspec_verify`
        # at the end of an example. Thus, we should always consider a
        # negative expectation fulfilled for the purposes of end-of-example
        # verification (which is where this is used).
        def expectation_fulfilled?
          true
        end

        private

        def invocation_order
          @invocation_order ||= {
            :should_not_receive => [nil],
            :with => [:should_receive],
            :and_return => [:with, :should_receive],
            :and_raise => [:with, :should_receive]
          }
        end
      end
    end
  end
end
