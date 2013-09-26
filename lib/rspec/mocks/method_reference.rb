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

      # A method is implemented if sending the message to the object will
      # result in a reply. It might be dynamically implemented by
      # `method_missing`.
      def implemented?
        @module_reference.when_loaded do |m|
          method_implemented?(m)
        end
      end

      # A method is defined if the method is already defined on the object's
      # class. In that case, we can create a method object for it and assert
      # against metadata like arity.
      def defined?
        @module_reference.when_loaded do |m|
          method_defined?(m)
        end
      end

      def when_defined(&block)
        yield original_method if original_method
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

      def method_defined?(m)
        m.method_defined?(@method_name)
      end

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
