module RSpec
  module Mocks

    # An abstraction in front of objects so that non-loaded objects can be
    # worked with. The null case is for concrete objects that are always
    # loaded. See `ModuleReference` for an example of non-loaded objects.
    class ObjectReference
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

    # Provides a consistent interface for dealing with modules that may or may
    # not be defined.
    #
    # @private
    class ModuleReference
      def initialize(module_or_name)
        case module_or_name
          when Module then @module = module_or_name
          when String then @name   = module_or_name
          else raise ArgumentError,
            "Module or String expected, got #{module_or_name.inspect}"
        end
      end

      def defined?
        !!original_module
      end

      def const_to_replace
        @name || @module.name
      end

      alias_method :description, :const_to_replace

      def when_loaded(&block)
        yield original_module if original_module
      end

      private

      def original_module
        @module ||= Constant.original(@name).original_value
      end
    end
  end
end
