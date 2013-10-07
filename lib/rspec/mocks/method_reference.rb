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

      private
      def original_method
        @module_reference.when_loaded do |m|
          self.defined? && find_method(m)
        end
      end
    end

    # @private
    class InstanceMethodReference < MethodReference
      def method_implemented?(m)
        m.method_defined?(@method_name)
      end

      # Ideally, we'd use `respond_to?` for `method_implemented?` but we need a
      # reference to an instance to do that and we don't have one.  Note that
      # we may get false negatives: if the method is implemented via
      # `method_missing`, we'll return `false` even though it meets our
      # definition of "implemented". However, it's the best we can do.
      alias method_defined? method_implemented?

      def find_method(m)
        m.instance_method(@method_name)
      end
    end

    # @private
    class ClassMethodReference < MethodReference
      def method_implemented?(m)
        m.respond_to?(@method_name)
      end

      def method_defined?(m)
        (class << m; self; end).method_defined?(@method_name)
      end

      def find_method(m)
        m.method(@method_name)
      end
    end
  end
end
