module RSpec
  module Mocks
    # @private
    class ProxyForNil < Proxy

      def initialize
        @warn_about_expectations = true
        super nil
      end
      attr_accessor :warn_about_expectations

      def add_message_expectation(location, method_name, opts={}, &block)
        warn_when_warning_about_expectations method_name
        super
      end

      def add_negative_message_expectation(location, method_name, &implementation)
        warn_when_warning_about_expectations method_name
        super
      end

      def add_stub(location, method_name, opts={}, &implementation)
        warn_when_warning_about_expectations method_name
        super
      end

      private

      def warn_when_warning_about_expectations method_name
        warn( method_name ) if warn_about_expectations
      end

      def warn method_name
        Kernel.warn("An expectation of :#{method_name} was set on nil. Called from #{caller[3]}. Use allow_message_expectations_on_nil to disable warnings.")
      end

    end
  end
end
