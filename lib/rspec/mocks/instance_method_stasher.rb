module RSpec
  module Mocks
    # @private
    class InstanceMethodStasher
      def initialize(object, method)
        @object = object
        @method = method
        @klass = (class << object; self; end)

        @original_method = nil
      end

      attr_reader :original_method

      # @private
      def method_is_stashed?
        !!@original_method
      end

      # @private
      def stash
        return unless method_defined_directly_on_klass?
        @original_method ||= ::RSpec::Support.method_handle_for(@object, @method)
        @klass.__send__(:undef_method, @method)
      end

      # @private
      def restore
        return unless @original_method

        if @klass.__send__(:method_defined?, @method)
          @klass.__send__(:undef_method, @method)
        end

        handle_restoration_failures do
          @klass.__send__(:define_method, @method, @original_method)
        end

        @original_method = nil
      end

      def handle_restoration_failures
        # No known reasons for restoration to fail on other rubies.
        yield
      end

    private

      # @private
      def method_defined_directly_on_klass?
        method_defined_on_klass? && method_owned_by_klass?
      end

      # @private
      def method_defined_on_klass?(klass=@klass)
        MethodReference.method_defined_at_any_visibility?(klass, @method)
      end

      def method_owned_by_klass?
        owner = @klass.instance_method(@method).owner

        # The owner of a method on a class which has been
        # `prepend`ed may actually be an instance, e.g.
        # `#<MyClass:0x007fbb94e3cd10>`, rather than the expected `MyClass`.
        owner = owner.class unless Module === owner

        owner == @klass || !(method_defined_on_klass?(owner))
      end
    end
  end
end
