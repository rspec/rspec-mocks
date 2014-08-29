module RSpec
  module Mocks
    # @private
    class ObjectReference
      # Returns an appropriate Object or Module reference based
      # on the given argument.
      def self.for(object_module_or_name, allow_direct_object_refs=false)
        case object_module_or_name
        when Module then DirectModuleReference.new(object_module_or_name)
        when String then NamedObjectReference.new(object_module_or_name)
        else
          if allow_direct_object_refs
            DirectObjectReference.new(object_module_or_name)
          else
            raise ArgumentError,
                  "Module or String expected, got #{object_module_or_name.inspect}"
          end
        end
      end
    end

    # Used when an object is passed to `object_double`.
    # Represents a reference to that object.
    #
    # @private
    class DirectObjectReference
      def initialize(object)
        @object = object
      end

      def description
        @object.inspect
      end

      def const_to_replace
        raise ArgumentError,
              "Can not perform constant replacement with an object."
      end

      def defined?
        true
      end

      def when_loaded
        yield @object
      end
    end

    # Used when a module is passed to `class_double` or `instance_double`.
    # Represents a reference to that module.
    #
    # @private
    class DirectModuleReference < DirectObjectReference
      def const_to_replace
        @object.name
      end
      alias description const_to_replace
    end

    # Used when a string is passed to `class_double`, `instance_double`
    # or `object_double`.
    # Represents a reference to the object named (via a constant lookup)
    # by the string.
    #
    # @private
    class NamedObjectReference
      def initialize(const_name)
        @const_name = const_name
      end

      def defined?
        !!object
      end

      def const_to_replace
        @const_name
      end
      alias description const_to_replace

      def when_loaded(&_block)
        yield object if object
      end

    private

      def object
        @object ||= Constant.original(@const_name).original_value
      end
    end
  end
end
