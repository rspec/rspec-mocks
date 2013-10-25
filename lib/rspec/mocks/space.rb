module RSpec
  module Mocks
    # @api private
    class Space
      attr_reader :proxies, :any_instance_recorders

      def initialize
        @proxies                 = {}
        @any_instance_recorders  = {}
      end

      def verify_all
        proxies.each_value do |object|
          object.verify
        end

        any_instance_recorders.each_value do |recorder|
          recorder.verify
        end
      end

      def reset_all
        ConstantMutator.reset_all

        proxies.each_value do |object|
          object.reset
        end

        proxies.clear
        any_instance_recorders.clear
        expectation_ordering.clear
      end

      def expectation_ordering
        @expectation_ordering ||= OrderGroup.new
      end

      def any_instance_recorder_for(klass)
        id = klass.__id__
        any_instance_recorders.fetch(id) do
          any_instance_recorders[id] = AnyInstance::Recorder.new(klass)
        end
      end

      def remove_any_instance_recorder_for(klass)
        any_instance_recorders.delete(klass.__id__)
      end

      def proxies_of(klass)
        proxies.values.select { |proxy| klass === proxy.object }
      end

      def proxy_for(object)
        id = id_for(object)
        proxies.fetch(id) do
          proxies[id] = case object
                        when NilClass   then ProxyForNil.new(expectation_ordering)
                        when TestDouble then object.__build_mock_proxy(expectation_ordering)
                        else
                          if RSpec::Mocks.configuration.verify_partial_doubles?
                            VerifyingPartialMockProxy.new(object, expectation_ordering)
                          else
                            PartialMockProxy.new(object, expectation_ordering)
                          end
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

          object.instance_exec do
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
