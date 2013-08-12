module RSpec
  module Mocks
    module Matchers
      class ReceivesMessages

        def initialize(message_value_hash)
          @message_value_hash = message_value_hash
        end

        def setup_expectation(subject, &block)
          map_to proxy_on(subject), :add_simple_expectation
        end
        alias matches?                   setup_expectation
        alias does_not_match?            setup_expectation
        alias setup_negative_expectation setup_expectation
        alias setup_allowance            setup_expectation

        def setup_allowance(subject)
          map_to proxy_on(subject), :add_simple_stub
        end

        def setup_any_instance_expectation(subject)
          map_to_as_chain any_instance_of(subject), :should_receive
        end

        def setup_any_instance_negative_expectation(subject)
          map_to_as_chain any_instance_of(subject), :should_not_receive
        end

        def setup_any_instance_allowance(subject)
          any_instance_of(subject).stub(@message_value_hash)
        end

      private

        def proxy_on(subject)
          ::RSpec::Mocks.proxy_for(subject)
        end

        def any_instance_of(subject)
          ::RSpec::Mocks.any_instance_recorder_for(subject)
        end

        def map_to(host, method_name)
          @message_value_hash.each do |message, value|
            host.__send__(method_name, message.to_sym, value)
          end
        end

        def map_to_as_chain(host, method_name, *args)
          @message_value_hash.each do |message, value|
            host.__send__(method_name, message, *args).and_return(value)
          end
        end

      end
    end
  end
end
