module RSpec
  module Mocks
    # @api private
    class Space
      attr_reader :mock_proxies

      def initialize
        @mock_proxies = {}
      end

      def verify_all
        mock_proxies.values.each do |object|
          object.verify
        end

        AnyInstance.verify_all
      end

      def reset_all
        ConstantMutator.reset_all
        AnyInstance.reset_all

        mock_proxies.values.each do |object|
          object.reset
        end

        mock_proxies.clear
        expectation_ordering.clear
      end

      def expectation_ordering
        @expectation_ordering ||= OrderGroup.new
      end

      def mock_proxy_for(object)
        mock_proxies.fetch(object.object_id) do
          mock_proxies[object.object_id] = if TestDouble === object
            object.__build_mock_proxy
          else
            Proxy.new(object)
          end
        end
      end

      alias ensure_registered mock_proxy_for

      def registered?(object)
        mock_proxies.has_key?(object.object_id)
      end
    end
  end
end
