module RSpec
  module Mocks
    module Matchers
      class ReceivesMessages

        def initialize(message_value_hash)
          @receivers = message_value_hash.map do |method_name, value|
            Matchers::Receive.new(method_name, proc { value })
          end
        end

        %w[
          setup_expecation matches? setup_negative_expectation does_not_match?
          setup_allowance setup_any_instance_expectation setup_any_instance_expectation
          setup_any_instance_negative_expectation setup_any_instance_allowance
        ].each do |method_name|
          define_method(method_name) do |subject, &block|
            @receivers.each do |receiver|
              receiver.send(method_name, subject, &block)
            end
          end
        end

        MessageExpectation.public_instance_methods(false).each do |method_name|
          next if method_defined?(method_name)

          define_method(method_name) do |*args, &block|
            @receivers.each do |receiver|
              receiver.send(method_name, *args, &block)
            end
            self
          end
        end
      end
    end
  end
end
