module RSpec
  module Mocks
    module Warning
      # @private
      #
      # Used internally to print deprecation warnings
      def warning(text, options={})
        warn_with "WARNING: #{text}.", options
      end

      def warn_with(message, options = {})
        line = caller.find { |line| line !~ %r{/lib/rspec/(core|mocks|expectations|matchers|rails)/} }
        message << " Use #{options[:replacement]} instead." if options[:replacement]
        message << " Called from #{line}."
        ::Kernel.warn message
      end
    end
  end

  extend(Mocks::Warning) unless respond_to?(:warning) && respond_to?(:warn_with)
end

