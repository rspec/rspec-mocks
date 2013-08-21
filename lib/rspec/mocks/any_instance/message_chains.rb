module RSpec
  module Mocks
    module AnyInstance
      # @private
      class MessageChains
        def initialize
          @chains_by_method_name = Hash.new { |h, k| h[k] = [] }
        end

        # @private
        def [](method_name)
          @chains_by_method_name[method_name]
        end

        # @private
        def add(method_name, chain)
          @chains_by_method_name[method_name] << chain
          chain
        end

        # @private
        def remove_stub_chains_for!(method_name)
          @chains_by_method_name[method_name].reject! do |chain|
            StubChain === chain
          end
        end

        # @private
        def has_expectation?(method_name)
          @chains_by_method_name[method_name].find do |chain|
            ExpectationChain === chain
          end
        end

        # @private
        def all_expectations_fulfilled?
          @chains_by_method_name.all? do |method_name, chains|
            chains.all? { |chain| chain.expectation_fulfilled? }
          end
        end

        # @private
        def unfulfilled_expectations
          @chains_by_method_name.map do |method_name, chains|
            method_name.to_s if ExpectationChain === chains.last unless chains.last.expectation_fulfilled?
          end.compact
        end

        # @private
        def received_expected_message!(method_name)
          @chains_by_method_name[method_name].each do |chain|
            chain.expectation_fulfilled!
          end
        end

        # @private
        def playback!(instance, method_name)
          raise_if_second_instance_to_receive_message(instance)
          @chains_by_method_name[method_name].each do |chain|
            chain.playback!(instance)
          end
        end

        private

        def raise_if_second_instance_to_receive_message(instance)
          @instance_with_expectation ||= instance if ExpectationChain === instance
          if ExpectationChain === instance && !@instance_with_expectation.equal?(instance)
            raise RSpec::Mocks::MockExpectationError, "Exactly one instance should have received the following message(s) but didn't: #{unfulfilled_expectations.sort.join(', ')}"
          end
        end
      end
    end
  end
end
