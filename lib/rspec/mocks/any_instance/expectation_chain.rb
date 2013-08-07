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
          me = proxy.add_message_expectation(expected_from, *@expectation_args, &@expectation_block)
          if RSpec::Mocks.configuration.yield_receiver_to_any_instance_implementation_blocks?
            me.and_yield_receiver_to_implementation
          end

          warn_about_receiver_passing_if_necessary

          me
        end

        def invocation_order
          @invocation_order ||= {
            :with => [nil],
            :and_return => [:with, nil],
            :and_raise => [:with, nil]
          }
        end

        def warn_about_receiver_passing_if_necessary
          RSpec.warn_deprecation(<<MSG
In RSpec 3, `any_instance` implementation blocks will be yielded the receiving
instance as the first block argument to allow the implementation block to use
the state of the receiver.  To maintain compatibility with RSpec 3 you need to
either set rspec-mocks' `yield_receiver_to_any_instance_implementation_blocks`
config option to `false` OR set it to `true` and update your `any_instance`
implementation blocks to account for the first block argument being the receiving instance.

To set the config option, use a snippet like:

RSpec.configure do |rspec|
  rspec.mock_with :rspec do |mocks|
    mocks.yield_receiver_to_any_instance_implementation_blocks = false
  end
end
MSG
          ) if RSpec::Mocks.configuration.should_warn_about_any_instance_blocks?
        end
      end
    end
  end
end

