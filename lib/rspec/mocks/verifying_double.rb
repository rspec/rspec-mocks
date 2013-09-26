require 'rspec/mocks/mock'
require 'rspec/mocks/verifying_proxy'

module RSpec
  module Mocks

    module VerifyingDouble
      def method_missing(message, *args, &block)
        # Null object conditional is an optimization. If not a null object,
        # validity of method expectations will have been checked at definition
        # time.
        __mock_proxy.ensure_implemented(message) if null_object?
        super
      end
    end

    # A mock providing a custom proxy that can verify the validity of any
    # method stubs or expectations against the public instance methods of the
    # given class.
    class InstanceVerifyingDouble
      include TestDouble
      include VerifyingDouble

      def initialize(doubled_module, *args)
        @doubled_module = doubled_module

        __initialize_as_test_double(doubled_module, *args)
      end

      def __build_mock_proxy
        VerifyingProxy.new(self,
          @doubled_module,
          lambda { |cls, method_name| cls.method_defined? method_name },
          lambda { |cls, method_name| cls.method_defined? method_name },
          lambda { |cls, method_name| cls.instance_method method_name },
        )
      end
    end

    # Similar to an InstanceVerifyingDouble, except that it verifies against
    # public methods of the given class (i.e. the "class methods").
    #
    # Module needs to be in the inheritance chain for transferring nested
    # constants to work.
    class ClassVerifyingDouble < Module
      include TestDouble
      include VerifyingDouble

      def initialize(doubled_module, *args)
        @doubled_module = doubled_module

        __initialize_as_test_double(doubled_module, *args)
      end

      def __build_mock_proxy
        VerifyingProxy.new(self,
          @doubled_module,
          lambda { |cls, method_name| cls.respond_to? method_name },
          lambda { |cls, method_name| cls.singleton_class.method_defined? method_name },
          lambda { |cls, method_name| cls.method method_name },
        )
      end

      def as_stubbed_const(options = {})
        ConstantMutator.stub(@doubled_module.name, self, options)
        self
      end
    end

  end
end
