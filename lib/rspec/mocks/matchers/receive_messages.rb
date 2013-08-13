module RSpec
  module Mocks
    module Matchers
      class ReceiveMessages

        def initialize(message_return_value_hash)
          @message_return_value_hash = message_return_value_hash
          @backtrace_line = CallerFilter.first_non_rspec_line
        end

        def setup_expectation(subject, &block)
          each_message_on( proxy_on(subject) ) do |host, message, return_value|
            host.add_simple_expectation(message, return_value, @backtrace_line)
          end
        end
        alias matches? setup_expectation

        def setup_allowance(subject)
          each_message_on( proxy_on(subject) ) do |host, message, return_value|
            host.add_simple_stub(message, return_value)
          end
        end

        def setup_any_instance_expectation(subject)
          each_message_on( any_instance_of(subject) ) do |host, message, return_value|
            host.should_receive(message).and_return(return_value)
          end
        end

        def setup_any_instance_allowance(subject)
          any_instance_of(subject).stub(@message_return_value_hash)
        end

      private

        def proxy_on(subject)
          ::RSpec::Mocks.proxy_for(subject)
        end

        def any_instance_of(subject)
          ::RSpec::Mocks.any_instance_recorder_for(subject)
        end

        def each_message_on(host)
          @message_return_value_hash.each do |message, value|
            yield host, message, value
          end
        end

      end
    end
  end
end
