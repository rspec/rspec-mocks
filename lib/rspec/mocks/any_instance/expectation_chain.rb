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
          proxy = ::RSpec::Mocks.space.proxy_for(instance)
          expected_from = IGNORED_BACKTRACE_LINE
          me = proxy.add_message_expectation(expected_from, *@expectation_args, &@expectation_block)
          if RSpec::Mocks.configuration.yield_receiver_to_any_instance_implementation_blocks?
            me.and_yield_receiver_to_implementation
          end

          me
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
