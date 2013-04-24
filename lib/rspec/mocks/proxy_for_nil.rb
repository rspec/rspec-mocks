module RSpec
  module Mocks
    # @private
    class ProxyForNil < Proxy

      def initialize
        super nil
      end

      def reset
        reset_nil_expectations_warning
        super
      end

      private

      def reset_nil_expectations_warning
        RSpec::Mocks::Proxy.warn_about_expectations_on_nil = true
      end

    end
  end
end
