module RSpec
  module Mocks
    # @private
    class Proxy
      SpecificMessage = Struct.new(:object,:message) do
        def ==(expectation)
          expectation.orig_object == object && expectation.message == message
        end
      end

      # @private
      def initialize(object, order_group, name=nil, options={})
        @object = object
        @order_group = order_group
        @name = name
        @error_generator = ErrorGenerator.new(object, name)
        @messages_received = []
        @options = options
        @null_object = false
        @method_doubles = Hash.new { |h, k| h[k] = MethodDouble.new(@object, k, self) }
      end

      # @private
      attr_reader :object

      # @private
      def null_object?
        @null_object
      end

      # @private
      # Tells the object to ignore any messages that aren't explicitly set as
      # stubs or message expectations.
      def as_null_object
        @null_object = true
        @object
      end

      # @private
      def method_handle_for(message)
        nil
      end

      # @private
      def add_message_expectation(location, method_name, opts={}, &block)
        meth_double = method_double_for(method_name)

        if null_object? && !block
          meth_double.add_default_stub(@error_generator, @order_group, location, opts) do
            @object
          end
        end

        meth_double.add_expectation @error_generator, @order_group, location, opts, &block
      end

      # @private
      def add_simple_expectation(method_name, response, location)
        method_double_for(method_name).add_simple_expectation method_name, response, @error_generator, location
      end

      # @private
      def build_expectation(method_name)
        meth_double = method_double_for(method_name)

        meth_double.build_expectation(
          @error_generator,
          @order_group
        )
      end

      # @private
      def replay_received_message_on(expectation, &block)
        expected_method_name = expectation.message
        meth_double = method_double_for(expected_method_name)

        if meth_double.expectations.any?
          @error_generator.raise_expectation_on_mocked_method(expected_method_name)
        end

        unless null_object? || meth_double.stubs.any?
          @error_generator.raise_expectation_on_unstubbed_method(expected_method_name)
        end

        @messages_received.each do |(actual_method_name, args, _)|
          if expectation.matches?(actual_method_name, *args)
            expectation.invoke(nil)
            block.call(*args) if block
          end
        end

      end

      # @private
      def check_for_unexpected_arguments(expectation)
        @messages_received.each do |(method_name, args, _)|
          if expectation.matches_name_but_not_args(method_name, *args)
            raise_unexpected_message_args_error(expectation, *args)
          end
        end
      end

      # @private
      def add_stub(location, method_name, opts={}, &implementation)
        method_double_for(method_name).add_stub @error_generator, @order_group, location, opts, &implementation
      end

      # @private
      def add_simple_stub(method_name, response)
        method_double_for(method_name).add_simple_stub method_name, response
      end

      # @private
      def remove_stub(method_name)
        method_double_for(method_name).remove_stub
      end

      # @private
      def remove_single_stub(method_name, stub)
        method_double_for(method_name).remove_single_stub(stub)
      end

      # @private
      def verify
        @method_doubles.each_value {|d| d.verify}
      end

      # @private
      def reset
        @messages_received.clear
      end

      # @private
      def received_message?(method_name, *args, &block)
        @messages_received.any? {|array| array == [method_name, args, block]}
      end

      # @private
      def has_negative_expectation?(message)
        method_double_for(message).expectations.detect {|expectation| expectation.negative_expectation_for?(message)}
      end

      # @private
      def record_message_received(message, *args, &block)
        @order_group.invoked SpecificMessage.new(object, message)
        @messages_received << [message, args, block]
      end

      # @private
      def message_received(message, *args, &block)
        record_message_received message, *args, &block
        expectation = find_matching_expectation(message, *args)
        stub = find_matching_method_stub(message, *args)

        if (stub && expectation && expectation.called_max_times?) || (stub && !expectation)
          expectation.increase_actual_received_count! if expectation && expectation.actual_received_count_matters?
          if expectation = find_almost_matching_expectation(message, *args)
            expectation.advise(*args) unless expectation.expected_messages_received?
          end
          stub.invoke(nil, *args, &block)
        elsif expectation
          expectation.invoke(stub, *args, &block)
        elsif expectation = find_almost_matching_expectation(message, *args)
          expectation.advise(*args) if null_object? unless expectation.expected_messages_received?
          raise_unexpected_message_args_error(expectation, *args) unless (has_negative_expectation?(message) or null_object?)
        elsif stub = find_almost_matching_stub(message, *args)
          stub.advise(*args)
          raise_missing_default_stub_error(stub, *args)
        elsif Class === @object
          @object.superclass.__send__(message, *args, &block)
        else
          @object.__send__(:method_missing, message, *args, &block)
        end
      end

      # @private
      def raise_unexpected_message_error(method_name, *args)
        @error_generator.raise_unexpected_message_error method_name, *args
      end

      # @private
      def raise_unexpected_message_args_error(expectation, *args)
        @error_generator.raise_unexpected_message_args_error(expectation, *args)
      end

      # @private
      def raise_missing_default_stub_error(expectation, *args)
        @error_generator.raise_missing_default_stub_error(expectation, *args)
      end

      # @private
      def visibility_for(method_name)
        # This is the default (for test doubles). Subclasses override this.
        :public
      end

    private

      def method_double_for(message)
        @method_doubles[message.to_sym]
      end

      def find_matching_expectation(method_name, *args)
        find_best_matching_expectation_for(method_name) do |expectation|
          expectation.matches?(method_name, *args)
        end
      end

      def find_almost_matching_expectation(method_name, *args)
        find_best_matching_expectation_for(method_name) do |expectation|
          expectation.matches_name_but_not_args(method_name, *args)
        end
      end

      def find_best_matching_expectation_for(method_name)
        first_match = nil

        method_double_for(method_name).expectations.each do |expectation|
          next unless yield expectation
          return expectation unless expectation.called_max_times?
          first_match ||= expectation
        end

        first_match
      end

      def find_matching_method_stub(method_name, *args)
        method_double_for(method_name).stubs.find {|stub| stub.matches?(method_name, *args)}
      end

      def find_almost_matching_stub(method_name, *args)
        method_double_for(method_name).stubs.find {|stub| stub.matches_name_but_not_args(method_name, *args)}
      end
    end

    # @private
    class TestDoubleProxy < Proxy
      def reset
        @method_doubles.clear
        object.__disallow_further_usage!
        super
      end
    end

    # @private
    class PartialDoubleProxy < Proxy
      def method_handle_for(message)
        if any_instance_class_recorder_observing_method?(@object.class, message)
          message = ::RSpec::Mocks.space.
            any_instance_recorder_for(@object.class).
            build_alias_method_name(message)
        end

        ::RSpec::Support.method_handle_for(@object, message)
      rescue NameError
        nil
      end

      # @private
      def add_simple_expectation(method_name, response, location)
        method_double_for(method_name).configure_method
        super
      end

      # @private
      def add_simple_stub(method_name, response)
        method_double_for(method_name).configure_method
        super
      end

      # @private
      def visibility_for(method_name)
        # We fall back to :public because by default we allow undefined methods
        # to be stubbed, and when we do so, we make them public.
        MethodReference.method_visibility_for(@object, method_name) || :public
      end

      def reset
        @method_doubles.each_value {|d| d.reset}
        super
      end

    private

      def any_instance_class_recorder_observing_method?(klass, method_name)
        return true if ::RSpec::Mocks.space.any_instance_recorder_for(klass).already_observing?(method_name)
        superklass = klass.superclass
        return false if superklass.nil?
        any_instance_class_recorder_observing_method?(superklass, method_name)
      end
    end

    # @private
    class ProxyForNil < PartialDoubleProxy
      def initialize(order_group)
        @warn_about_expectations = true
        super(nil, order_group)
      end

      attr_accessor :warn_about_expectations
      alias warn_about_expectations? warn_about_expectations

      def add_message_expectation(location, method_name, opts={}, &block)
        warn(method_name) if warn_about_expectations?
        super
      end

      def add_negative_message_expectation(location, method_name, &implementation)
        warn(method_name) if warn_about_expectations?
        super
      end

      def add_stub(location, method_name, opts={}, &implementation)
        warn(method_name) if warn_about_expectations?
        super
      end

    private

      def warn method_name
        source = CallerFilter.first_non_rspec_line
        Kernel.warn("An expectation of :#{method_name} was set on nil. Called from #{source}. Use allow_message_expectations_on_nil to disable warnings.")
      end
    end
  end
end
