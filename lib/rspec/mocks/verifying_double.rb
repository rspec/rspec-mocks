require 'rspec/mocks/mock'
require 'rspec/mocks/verifying_message_expecation'

module RSpec
  module Mocks

    # A verifying proxy mostly acts like a normal proxy, except that it
    # contains extra logic to try and determine the validity of any expectation
    # set on it. This includes whether or not methods have been defined and the
    # arity of method calls.
    #
    # These checks are only activated if the doubled class has already been
    # loaded, otherwise they are disabled. This allows for testing in
    # isolation.
    class VerifyingProxy < Proxy
      include RecursiveConstMethods

      def initialize(object, name, checked_methods, method_finder)
        super(object)
        @object = object
        @__doubled_class_name = name
        @__checked_methods = checked_methods
        @__method_finder   = method_finder
      end

      # @override
      def add_stub(location, method_name, opts={}, &implementation)
        ensure_implemented(method_name)
        super
      end

      # @override
      def add_message_expectation(location, method_name, opts={}, &block)
        ensure_implemented(method_name)
        ret = super
        ret
      end

      # @override
      def method_double
        @method_double ||= Hash.new {|h,k|
          h[k] = VerifyingMethodDouble.new(@object, k, self).tap {|x|
            with_doubled_class do |doubled_class|
              x.method_finder = lambda {|method_name|
                doubled_class.send(@__method_finder, method_name)
              }
            end
          }
        }
      end

      class VerifyingMethodDouble < MethodDouble
        attr_accessor :method_finder

        def message_expectation_class
          VerifyingMessageExpectation
        end

        def add_expectation(*arg)
          ret = super
          ret.method_finder = method_finder
          ret
        end
      end

      protected

      # This cache gives a decent speed up when a class is doubled a lot.
      def implemented_methods(doubled_class, checked_methods)
        @@_implemented_methods_cache ||= {}

        # to_sym for non-1.9 compat
        @@_implemented_methods_cache[[doubled_class, checked_methods]] ||=
          doubled_class.__send__(checked_methods).map(&:to_sym)
      end

      def unimplemented_methods(doubled_class, expected_methods, checked_methods)
        expected_methods.map(&:to_sym) -
          implemented_methods(doubled_class, checked_methods)
      end

      def with_doubled_class
        if recursive_const_defined?(@__doubled_class_name)
          yield recursive_const_get(@__doubled_class_name)
        end
      end

      def ensure_implemented(*method_names)
        with_doubled_class do |doubled_class|
          methods = unimplemented_methods(
            doubled_class,
            method_names,
            @__checked_methods
          )

          if methods.any?
            raise RSpec::Expectations::ExpectationNotMetError,
              format_error_message(doubled_class, methods)
          end
        end
      end

      def format_error_message(doubled_class, methods)
        "%s does not implement:\n%s" % [
          doubled_class,
          methods.sort.map {|x|
            "  #{x}"
          }.join("\n")
        ]
      end
    end

    class InstanceVerifyingMock < RSpec::Mocks::Mock
      def initialize(doubled_class, *args)
        @__doubled_class_name = doubled_class
        super
      end

      def __build_mock_proxy
        VerifyingProxy.new(self,
          @__doubled_class_name,
          :public_instance_methods,
          :instance_method
        )
      end
    end

    class ClassVerifyingMock < RSpec::Mocks::Mock
      def initialize(doubled_class, *args)
        @__doubled_class_name = doubled_class
        super
      end

      def __build_mock_proxy
        VerifyingProxy.new(self,
          @__doubled_class_name,
          :public_methods,
          :method
        )
      end
    end
  end
end
