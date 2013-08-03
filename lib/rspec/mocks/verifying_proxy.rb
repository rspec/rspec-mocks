require 'rspec/mocks/verifying_message_expecation'

module RSpec
  module Mocks

    # A verifying proxy mostly acts like a normal proxy, except that it
    # contains extra logic to try and determine the validity of any expectation
    # set on it. This includes whether or not methods have been defined and the
    # arity of method calls.
    #
    # In all other ways this behaves like a normal proxy. It only adds the
    # verification behaviour to specific methods then delegates to the parent
    # implementation.
    #
    # These checks are only activated if the doubled class has already been
    # loaded, otherwise they are disabled. This allows for testing in
    # isolation.
    #
    # @api private
    class VerifyingProxy < Proxy
      def initialize(object, name, method_checker, method_finder)
        super(object)
        @object         = object
        @doubled_module = name
        @method_checker = method_checker
        @method_finder  = method_finder
      end

      def add_stub(location, method_name, opts={}, &implementation)
        ensure_implemented(method_name)
        super
      end

      def add_simple_stub(_, method_name, *args)
        ensure_implemented(method_name)
        super
      end

      def add_message_expectation(location, method_name, opts={}, &block)
        ensure_implemented(method_name)
        super
      end

      # A custom method double is required to pass through a way to lookup
      # methods to determine their arity. This is only relevant if the doubled
      # class is loaded.
      def method_double
        @method_double ||= Hash.new do |h,k|
          method_double = VerifyingMethodDouble.new(@object, k, self)

          @doubled_module.when_loaded do |original_module|
            method_double.method_finder = lambda do |method_name|
              original_module.__send__(@method_finder, method_name)
            end
          end

          h[k] = method_double
        end
      end

    protected

      def ensure_implemented(method_name)
        @doubled_module.when_loaded do |original_module|
          unless original_module.__send__(@method_checker, method_name)
            @error_generator.raise_unimplemented_error(
              @doubled_module,
              method_name
            )
          end
        end
      end
    end

    # @api private
    class VerifyingMethodDouble < MethodDouble
      attr_accessor :method_finder

      def message_expectation_class
        VerifyingMessageExpectation
      end

      def add_expectation(*arg)
        super.tap {|x| x.method_finder = method_finder if method_finder }
      end
    end

  end
end
