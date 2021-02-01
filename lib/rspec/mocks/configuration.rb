module RSpec
  module Mocks
    # Provides configuration options for rspec-mocks.
    class Configuration
      def initialize
        @allow_message_expectations_on_nil = nil
        @yield_receiver_to_any_instance_implementation_blocks = true
        @verify_doubled_constant_names = false
        @transfer_nested_constants = false
        @verify_partial_doubles = true
        @temporarily_suppress_partial_double_verification = false
        @color = false
      end

      # Sets whether RSpec will warn, ignore, or fail a test when
      # expectations are set on nil.
      # By default, when this flag is not set, warning messages are issued when
      # expectations are set on nil. This is to prevent false-positives and to
      # catch potential bugs early on.
      # When set to `true`, warning messages are suppressed.
      # When set to `false`, it will raise an error.
      #
      # @example
      #   RSpec.configure do |config|
      #     config.mock_with :rspec do |mocks|
      #       mocks.allow_message_expectations_on_nil = false
      #     end
      #   end
      attr_accessor :allow_message_expectations_on_nil

      def yield_receiver_to_any_instance_implementation_blocks?
        @yield_receiver_to_any_instance_implementation_blocks
      end

      # Sets whether or not RSpec will yield the receiving instance of a
      # message to blocks that are used for any_instance stub implementations.
      # When set, the first yielded argument will be the receiving instance.
      # Defaults to `true`.
      #
      # @example
      #   RSpec.configure do |rspec|
      #     rspec.mock_with :rspec do |mocks|
      #       mocks.yield_receiver_to_any_instance_implementation_blocks = false
      #     end
      #   end
      attr_writer :yield_receiver_to_any_instance_implementation_blocks

      def verify_doubled_constant_names?
        !!@verify_doubled_constant_names
      end

      # When this is set to true, an error will be raised when
      # `instance_double` or `class_double` is given the name of an undefined
      # constant. You probably only want to set this when running your entire
      # test suite, with all production code loaded. Setting this for an
      # isolated unit test will prevent you from being able to isolate it!
      attr_writer :verify_doubled_constant_names

      # Provides a way to perform customisations when verifying doubles.
      #
      # @example
      #  RSpec::Mocks.configuration.before_verifying_doubles do |ref|
      #    ref.some_method!
      #  end
      def before_verifying_doubles(&block)
        verifying_double_callbacks << block
      end
      alias :when_declaring_verifying_double :before_verifying_doubles

      # @api private
      # Returns an array of blocks to call when verifying doubles
      def verifying_double_callbacks
        @verifying_double_callbacks ||= []
      end

      def transfer_nested_constants?
        !!@transfer_nested_constants
      end

      # Sets the default for the `transfer_nested_constants` option when
      # stubbing constants.
      attr_writer :transfer_nested_constants

      # When set to true, partial mocks will be verified the same as object
      # doubles. Any stubs will have their arguments checked against the original
      # method, and methods that do not exist cannot be stubbed.
      def verify_partial_doubles=(val)
        @verify_partial_doubles = !!val
      end

      def verify_partial_doubles?
        @verify_partial_doubles
      end

      # @private
      # Used to track wether we are temporarily suppressing verifying partial
      # doubles with `without_partial_double_verification { ... }`
      attr_accessor :temporarily_suppress_partial_double_verification

      if ::RSpec.respond_to?(:configuration)
        def color?
          ::RSpec.configuration.color_enabled?
        end
      else
        # Indicates whether or not diffs should be colored.
        # Delegates to rspec-core's color option if rspec-core
        # is loaded; otherwise you can set it here.
        attr_writer :color

        # Indicates whether or not diffs should be colored.
        # Delegates to rspec-core's color option if rspec-core
        # is loaded; otherwise you can set it here.
        def color?
          @color
        end
      end

      # Monkey-patch `Marshal.dump` to enable dumping of mocked or stubbed
      # objects. By default this will not work since RSpec mocks works by
      # adding singleton methods that cannot be serialized. This patch removes
      # these singleton methods before serialization. Setting to falsey removes
      # the patch.
      #
      # This method is idempotent.
      def patch_marshal_to_support_partial_doubles=(val)
        if val
          RSpec::Mocks::MarshalExtension.patch!
        else
          RSpec::Mocks::MarshalExtension.unpatch!
        end
      end
    end

    # Mocks specific configuration, as distinct from `RSpec.configuration`
    # which is core RSpec configuration.
    def self.configuration
      @configuration ||= Configuration.new
    end
  end
end
