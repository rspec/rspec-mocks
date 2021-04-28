module RSpec
  module Mocks
    # @private
    class InstanceMethodStasher
      def initialize(object, method)
        @object = object
        @method = method
        # We don't want to create singleton class if it doesn't exist,
        # so we don't use `object.singleton_class`.
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
        # In Ruby 2.4 and earlier, `undef_method` is private
        @klass.__send__(:undef_method, @method)
      end

      # @private
      def restore
        return unless @original_method

        if @klass.method_defined?(@method)
          # In Ruby 2.4 and earlier, `undef_method` is private
          @klass.__send__(:undef_method, @method)
        end

        # In Ruby 2.4 and earlier, `define_method` is private
        @klass.__send__(:define_method, @method, @original_method)

        @original_method = nil
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

        owner == @klass ||
          # When `extend self` is used, and not under `allow_any_instance_of`
          # nor `expect_any_instance_of`.
          (owner.singleton_class == @klass &&
            !Mocks.space.any_instance_recorder_for(owner, true)) ||
          !(method_defined_on_klass?(owner))
      end
    end
  end
end
