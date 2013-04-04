module RSpec
  module Mocks
    # Provides configuration options for rspec-mocks.
    class Configuration
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
          Syntax.enable_direct(mod)
        end
      end

      def syntax=(values)
        if Array(values).include?(:wrapped)
          Syntax.enable_wrapped
        else
          Syntax.disable_wrapped
        end

        if Array(values).include?(:direct)
          Syntax.enable_direct
        else
          Syntax.disable_direct
        end
      end

      def syntax
        syntaxes = []
        syntaxes << :direct  if Syntax.direct_enabled?
        syntaxes << :wrapped if Syntax.wrapped_enabled?
        syntaxes
      end
    end

    def self.configuration
      @configuration ||= Configuration.new
    end

    configuration.syntax = :direct
  end
end

