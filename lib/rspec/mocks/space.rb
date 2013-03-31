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
        id = id_for(object)
        proxies.fetch(id) do
          proxies[id] = if TestDouble === object
                          object.__build_mock_proxy
                        else
                          Proxy.new(object)
                        end
        end
      end

      alias ensure_registered proxy_for

      def registered?(object)
        proxies.has_key?(id_for object)
      end

      if defined?(::BasicObject) && !::BasicObject.method_defined?(:__id__) # for 1.9.2
        require 'securerandom'

        def id_for(object)
          id = object.__id__

          return id if object.equal?(::ObjectSpace._id2ref(id))
          # this suggests that object.__id__ is proxying through to some wrapped object

          object.instance_eval do
            @__id_for_rspec_mocks_space ||= ::SecureRandom.uuid
          end
        end
      else
        def id_for(object)
          object.__id__
        end
      end
    end
  end
end
