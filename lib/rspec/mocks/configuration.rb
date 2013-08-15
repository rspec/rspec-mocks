module RSpec
  module Mocks
    # Provides configuration options for rspec-mocks.
    class Configuration

      def initialize
        @yield_receiver_to_any_instance_implementation_blocks = true
        @verify_doubled_constant_names = false
        @transfer_nested_constants = false
      end

      def yield_receiver_to_any_instance_implementation_blocks?
        @yield_receiver_to_any_instance_implementation_blocks
      end

      def yield_receiver_to_any_instance_implementation_blocks=(arg)
        @yield_receiver_to_any_instance_implementation_blocks = arg
      end

      # Adds `stub` and `should_receive` to the given
      # modules or classes. This is usually only necessary
      # if you application uses some proxy classes that
      # "strip themselves down" to a bare minimum set of
      # methods and remove `stub` and `should_receive` in
      # the process.
      #
      # @example
      #
      #   RSpec.configure do |rspec|
      #     rspec.mock_with :rspec do |mocks|
      #       mocks.add_stub_and_should_receive_to Delegator
      #     end
      #   end
      #
      def add_stub_and_should_receive_to(*modules)
        modules.each do |mod|
          Syntax.enable_should(mod)
        end
      end

      def syntax=(values)
        if Array(values).include?(:expect)
          Syntax.enable_expect
        else
          Syntax.disable_expect
        end

        if Array(values).include?(:should)
          Syntax.enable_should
        else
          Syntax.disable_should
        end
      end

      def syntax
        syntaxes = []
        syntaxes << :should  if Syntax.should_enabled?
        syntaxes << :expect if Syntax.expect_enabled?
        syntaxes
      end

      def verify_doubled_constant_names?
        !!@verify_doubled_constant_names
      end

      # When this is set to true, an error will be raised when
      # `instance_double` or `class_double` is given the name of an undefined
      # constant. You probably only want to set this when running your entire
      # test suite, with all production code loaded. Setting this for an
      # isolated unit test will prevent you from being able to isolate it!
      def verify_doubled_constant_names=(val)
        @verify_doubled_constant_names = val
      end

      def transfer_nested_constants?
        !!@transfer_nested_constants
      end

      # Sets the default for the `transfer_nested_constants` option when
      # stubbing constants.
      def transfer_nested_constants=(val)
        @transfer_nested_constants = val
      end
    end

    def self.configuration
      @configuration ||= Configuration.new
    end

    configuration.syntax = [:should, :expect]
  end
end

