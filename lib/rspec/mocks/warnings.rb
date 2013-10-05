module RSpec

  # We don't redefine the deprecation helpers
  # when they already exist (defined by rspec-core etc)
  unless respond_to?(:deprecate)

    # @private
    #
    # Used internally to print deprecation warnings
    def self.deprecate(deprecated, options = {})
      warn_with "DEPRECATION: #{deprecated} is deprecated.", options
    end

  end

  # We don't redefine the warnings helpers
  # when they already exist (defined by rspec-core etc)
  unless respond_to?(:warning) && respond_to?(:warn_with)

    # @private
    #
    # Used internally to print deprecation warnings
    def self.warning(text, options={})
      warn_with "WARNING: #{text}.", options
    end

    # @private
    #
    # Used internally to longer warnings
    def self.warn_with(message, options = {})
      message << " Use #{options[:replacement]} instead." if options[:replacement]
      message << " Called from #{CallerFilter.first_non_rspec_line}."
      ::Kernel.warn message
    end

  end
end
