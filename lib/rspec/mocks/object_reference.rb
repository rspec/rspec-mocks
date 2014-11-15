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
            DirectModuleReference.new(object_module_or_name)
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

      def const
        @object.class
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

      def const
        @object
      end
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

      def const
        object
      end

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
