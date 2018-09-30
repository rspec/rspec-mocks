module RSpec
  module Mocks
    # @private
    # @see RSpec::Mocks::Proxy
    # @see RSpec::Mocks::ReceivedMessage
    class ReceivedMessages
      def initialize(messages = [])
        @messages = messages
      end

      def empty?
        @messages.empty?
      end

      def any_matching_message_for?(expectation)
        @messages.any? { |message| expectation.matches?(message.name, *message.args) }
      end

      def <<(received_message)
        @messages << received_message
      end

      def [](*args)
        @messages[*args]
      end

      def clear
        @messages.clear
      end

      def replay_on(expectation, &with_block)
        @messages.each do |message|
          next unless expectation.matches?(message.name, *message.args)

          expectation.safe_invoke(nil)
          with_block.call(*message.args, &message.block) if with_block
        end
      end

      def received?(method_name, *args, &block)
        @messages.any? { |m| [m.name, m.args, m.block] == [method_name, args, block] }
      end

      def partition_by_matches_name_not_args_for(expectation)
        name_but_not_args, others = @messages.partition do |message|
          expectation.matches_name_but_not_args(message.name, *message.args)
        end
        [ReceivedMessages.new(name_but_not_args),
        ReceivedMessages.new(others)]
      end

      def all_args
        @messages.map { |message| message.args }
      end
    end
  end
end
