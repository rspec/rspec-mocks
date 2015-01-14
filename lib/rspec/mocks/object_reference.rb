module RSpec
  module Mocks
    # @private
    class ObjectReference
      # Returns an appropriate Object or Module reference based
      # on the given argument.
      def self.for(object_module_or_name, allow_direct_object_refs=false)
        case object_module_or_name
        when Module
          if anonymous_module?(object_module_or_name)
            AnonymousModuleReference.new(object_module_or_name)
          else
            # Use a `NamedObjectReference` if it has a name because this
            # will use the original value of the constant in case it has
            # been stubbed.
            NamedObjectReference.new(object_module_or_name.name)
          end
        when String
          NamedObjectReference.new(object_module_or_name)
        else
          if allow_direct_object_refs
            DirectObjectReference.new(object_module_or_name)
          else
            raise ArgumentError,
                  "Module or String expected, got #{object_module_or_name.inspect}"
          end
        end
      end

      if Module.new.name.nil?
        def self.anonymous_module?(mod)
          !mod.name
        end
      else # 1.8.7
        def self.anonymous_module?(mod)
          mod.name == ""
        end
      end
      private_class_method :anonymous_module?
    end

    # Used when an object is passed to `object_double`.
    # Represents a reference to that object.
    class DirectObjectReference
      # @param object to which this refers to.
      def initialize(object)
        @object = object
      end

      # The object's description (via `#inspect`).
      # @return String
      def description
        @object.inspect
      end

      # Defined for interface parity with the other object reference
      # implementations, it has no real relevance here.
      def const_to_replace
        raise ArgumentError,
              "Can not perform constant replacement with an object."
      end

      # The target of the verifying double (the object's class).
      #
      # @return Class
      def target
        @object.class
      end

      # Always returns true for an object as the class is defined.
      #
      # @return true
      def defined?
        true
      end

      # Yields if the reference target is loaded, providing a generic mechanism
      # to optionally run a bit of code only when a reference's target is
      # loaded.
      #
      # This specific implementation always yields because direct references
      # are always loaded.
      #
      # @yield object
      def when_loaded
        yield @object
      end
    end

    # Used when an anonymous module is passed to `class_double` or
    # `instance_double`. Represents a reference to that module.
    class AnonymousModuleReference < DirectObjectReference
      # Returns the constant name to replace with a double.
      #
      # @return String the constant name
      def const_to_replace
        @object.name
      end

      # Returns the module name.
      #
      # @return String the constant name
      alias description const_to_replace

      # The target of the verifying double (the module).
      #
      # @return Module
      def target
        @object
      end
    end

    # Used when a string is passed to `class_double`, `instance_double`
    # or `object_double`.
    # Represents a reference to the object named (via a constant lookup)
    # by the string.
    class NamedObjectReference
      # @param const_name [String] constant name
      def initialize(const_name)
        @const_name = const_name
      end

      # Returns true if the named constant is defined, false otherwise.
      #
      # @return Boolean
      def defined?
        !!object
      end

      # Returns the constant name to replace with a double.
      #
      # @return String the constant name
      def const_to_replace
        @const_name
      end

      # Returns the object constant name.
      #
      # @return String the constant name
      alias description const_to_replace

      # The target of the verifying double (the object).
      #
      # @return object
      def target
        object
      end

      # Yields if the reference target is loaded, providing a generic mechanism
      # to optionally run a bit of code only when a reference's target is
      # loaded.
      #
      # @yield object
      def when_loaded
        yield object if object
      end

    private

      def object
        return @object if defined?(@object)
        @object = Constant.original(@const_name).original_value
      end
    end
  end
end
