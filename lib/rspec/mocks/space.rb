module RSpec
  module Mocks
    # @api private
    class Space
      attr_reader :proxies

      def initialize
        @proxies = {}
      end

      def verify_all
        proxies.each_value do |object|
          object.verify
        end

        AnyInstance.verify_all
      end

      def reset_all
        ConstantMutator.reset_all
        AnyInstance.reset_all

        proxies.each_value do |object|
          object.reset
        end

        proxies.clear
        expectation_ordering.clear
      end

      def expectation_ordering
        @expectation_ordering ||= OrderGroup.new
      end

      def proxy_for(object)
        proxies.fetch(object.__id__) do
          proxies[object.__id__] = if TestDouble === object
                                      object.__build_mock_proxy
                                    else
                                      Proxy.new(object)
                                    end
        end
      end

      alias ensure_registered proxy_for

      def registered?(object)
        proxies.has_key?(object.__id__)
      end
    end
  end
end
