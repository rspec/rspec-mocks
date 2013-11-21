module RSpec
  module Mocks
    # Represents a method on a module that may or may not be defined.
    #
    # @private
    class MethodReference
      def initialize(module_reference, method_name)
        @module_reference = module_reference
        @method_name = method_name
      end

      # A method is implemented if sending the message does not result in
      # a `NoMethodError`. It might be dynamically implemented by
      # `method_missing`.
      def implemented?
        @module_reference.when_loaded do |m|
          method_implemented?(m)
        end
      end

      # A method is defined if we are able to get a `Method` object for it.
      # In that case, we can assert against metadata like the arity.
      def defined?
        @module_reference.when_loaded do |m|
          method_defined?(m)
        end
      end

      def when_defined
        if original = original_method
          yield original
        end
      end

      # Yields to the block if the method is not implemented.
      def when_unimplemented
        yield unless implemented?
      end

      def visibility
        @module_reference.when_loaded do |m|
          return visibility_from(m)
        end

        # When it's not loaded, assume it's public. We don't want to
        # wrongly treat the method as private.
        :public
      end

      private

      def original_method
        @module_reference.when_loaded do |m|
          self.defined? && find_method(m)
        end
      end

      def self.visibility_for(klass, method_name)
        if klass.private_method_defined?(method_name)
          :private
        elsif klass.protected_method_defined?(method_name)
          :protected
        elsif klass.method_defined?(method_name)
          :public
        end
      end
    end

    # @private
    class InstanceMethodReference < MethodReference
      private
      def method_implemented?(m)
        m.method_defined?(@method_name) || m.private_method_defined?(@method_name)
      end

      # Ideally, we'd use `respond_to?` for `method_implemented?` but we need a
      # reference to an instance to do that and we don't have one.  Note that
      # we may get false negatives: if the method is implemented via
      # `method_missing`, we'll return `false` even though it meets our
      # definition of "implemented". However, it's the best we can do.
      alias method_defined? method_implemented?

      # works around the fact that repeated calls for method parameters will
      # falsely return empty arrays on JRuby in certain circumstances, this
      # is necessary here because we can't dup/clone UnboundMethods.
      #
      # This is necessary due to a bug in JRuby prior to 1.7.5 fixed in:
      # https://github.com/jruby/jruby/commit/99a0613fe29935150d76a9a1ee4cf2b4f63f4a27
      if RUBY_PLATFORM == 'java' && JRUBY_VERSION.split('.')[-1].to_i < 5
        def find_method(m)
          m.dup.instance_method(@method_name)
        end
      else
        def find_method(m)
          m.instance_method(@method_name)
        end
      end

      def visibility_from(m)
        MethodReference.visibility_for(m, @method_name)
      end
    end

    # @private
    class ObjectMethodReference < MethodReference
      private
      def method_implemented?(m)
        m.respond_to?(@method_name, true)
      end

      def method_defined?(m)
        (class << m; self; end).method_defined?(@method_name)
      end

      def find_method(m)
        m.method(@method_name)
      end

      def visibility_from(m)
        MethodReference.visibility_for(class << m; self; end, @method_name).tap do |vis|
          # If the method is not defined on the class, `visibility_for` returns `nil`.
          # However, it may be handled dynamically by `method_missing`, so here we
          # check `respond_to` (passing false to not check private methods).
          #
          # This only considers the :public case, but I don't think it's possible to
          # write `method_missing` in such a way that it handles a dynamic message
          # with private or protected visibility. Ruby doesn't provide you with
          # the caller info.
          return :public if vis.nil? && m.respond_to?(@method_name, false)
        end
      end
    end
  end
end