module RSpec
  module Mocks
    # @private
    class MethodDouble
      # @private
      attr_reader :method_name, :object, :expectations, :stubs

      # @private
      def initialize(object, method_name, proxy)
        @method_name = method_name
        @object = object
        @proxy = proxy

        @original_visibility = nil
        @method_stasher = InstanceMethodStasher.new(object, method_name)
        @method_is_proxied = false
        @expectations = []
        @stubs = []
      end

      def original_method
        @original_method ||= Proc.new do |*args, &block|
          @object.__send__(:method_missing, @method_name, *args, &block)
        end
      end

      # @private
      def visibility
        if TestDouble === @object
          'public'
        elsif object_singleton_class.private_method_defined?(@method_name)
          'private'
        elsif object_singleton_class.protected_method_defined?(@method_name)
          'protected'
        else
          'public'
        end
      end

      # @private
      def object_singleton_class
        class << @object; self; end
      end

      # @private
      def configure_method
        @original_visibility = [visibility, method_name]
        @method_stasher.stash unless @method_is_proxied
        define_proxy_method
      end

      # @private
      def define_proxy_method
        return if @method_is_proxied

        @original_method = @method_stasher.original_method ||
                           @proxy.method_handle_for(method_name)

        object_singleton_class.class_exec(method_name, visibility) do |method_name, visibility|
          define_method(method_name) do |*args, &block|
            ::RSpec::Mocks.proxy_for(self).message_received method_name, *args, &block
          end
          self.__send__ visibility, method_name
        end

        @method_is_proxied = true
      end

      # @private
      def restore_original_method
        return unless @method_is_proxied

        object_singleton_class.__send__(:remove_method, @method_name)
        if @method_stasher.method_is_stashed?
          @method_stasher.restore
        end
        restore_original_visibility

        @method_is_proxied = false
      end

      # @private
      def restore_original_visibility
        return unless @original_visibility &&
          (object_singleton_class.method_defined?(@method_name) ||
           object_singleton_class.private_method_defined?(@method_name))

        object_singleton_class.__send__(*@original_visibility)
      end

      # @private
      def verify
        expectations.each {|e| e.verify_messages_received}
      end

      # @private
      def reset
        restore_original_method
        clear
      end

      # @private
      def clear
        expectations.clear
        stubs.clear
      end

      # The type of message expectation to create has been extracted to its own
      # method so that subclasses can override it.
      #
      # @private
      def message_expectation_class
        MessageExpectation
      end

      # @private
      def add_expectation(error_generator, expectation_ordering, expected_from, opts, &implementation)
        configure_method
        expectation = message_expectation_class.new(error_generator, expectation_ordering,
                                             expected_from, self, 1, opts, &implementation)
        expectations << expectation
        expectation
      end

      # @private
      def build_expectation(error_generator, expectation_ordering)
        expected_from = IGNORED_BACKTRACE_LINE
        message_expectation_class.new(error_generator, expectation_ordering, expected_from, self)
      end

      # @private
      def add_stub(error_generator, expectation_ordering, expected_from, opts={}, &implementation)
        configure_method
        stub = message_expectation_class.new(error_generator, expectation_ordering, expected_from,
                                      self, :any, opts, &implementation)
        stubs.unshift stub
        stub
      end

      # A simple stub can only return a concrete value for a message, and
      # cannot match on arguments. It is used as an optimization over
      # `add_stub` where it is known in advance that this is all that will be
      # required of a stub, such as when passing attributes to the `double`
      # example method. They do not stash or restore existing method
      # definitions.
      #
      # @private
      def add_simple_stub(method_name, response)
        define_proxy_method

        stub = SimpleMessageExpectation.new(method_name, response)
        stubs.unshift stub
        stub
      end

      # @private
      def add_default_stub(*args, &implementation)
        return if stubs.any?
        add_stub(*args, &implementation)
      end

      # @private
      def remove_stub
        raise_method_not_stubbed_error if stubs.empty?
        expectations.empty? ? reset : stubs.clear
      end

      # @private
      def raise_method_not_stubbed_error
        raise MockExpectationError, "The method `#{method_name}` was not stubbed or was already unstubbed"
      end

      # @private
      IGNORED_BACKTRACE_LINE = 'this backtrace line is ignored'
    end
  end
end
