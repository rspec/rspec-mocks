require 'rspec/mocks/framework'
require 'rspec/mocks/version'
require 'rspec/mocks/example_methods'

module RSpec
  module Mocks
    class << self
      attr_accessor :space

      def setup(host)
        add_extensions unless extensions_added?
        (class << host; self; end).class_eval do
          include RSpec::Mocks::ExampleMethods
        end
        self.space ||= RSpec::Mocks::Space.new
      end

      def verify
        space.verify_all
      end

      def teardown
        space.reset_all
      end

      def configuration
        @configuration ||= Configuration.new
      end

      # @api private
      # Used internally by RSpec to display custom deprecation warnings.  This
      # is also defined in rspec-core, but we can't assume it's loaded since
      # rspec-expectations should be usable w/o rspec-core.
      def warn_deprecation(message)
        warn(message)
      end

    private

      def add_extensions
        method_host.class_eval { include RSpec::Mocks::Methods }
        Class.class_eval  { include RSpec::Mocks::AnyInstance }
        $_rspec_mocks_extensions_added = true
      end

      def extensions_added?
        defined?($_rspec_mocks_extensions_added)
      end

      def method_host
        # On 1.8.7, Object.ancestors.last == Kernel but
        # things blow up if we include `RSpec::Mocks::Methods`
        # into Kernel...not sure why.
        return Object unless defined?(::BasicObject)

        # MacRuby has BasicObject but it's not the root class.
        return Object unless Object.ancestors.last == ::BasicObject

        ::BasicObject
      end
    end
  end
end
