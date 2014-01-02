require 'rspec/mocks/framework'
require 'rspec/mocks/version'
require 'rspec/support'
require "rspec/mocks/error_space"

module RSpec
  # Contains top-level utility methods. While this contains a few
  # public methods, these are not generally meant to be called from
  # a test or example. They exist primarily for integration with
  # test frameworks (such as rspec-core).
  module Mocks
    ERROR_SPACE = RSpec::Mocks::ErrorSpace.new
    MOCK_SPACE = RSpec::Mocks::Space.new

    class << self
      # Stores rspec-mocks' global state.
      # @api private
      attr_accessor :space
    end

    self.space = ERROR_SPACE

    # Performs per-test/example setup. This should be called before
    # an test or example begins.
    def self.setup(host=nil)
      self.space = MOCK_SPACE
    end

    # Verifies any message expectations that were set during the
    # test or example. This should be called at the end of an example.
    def self.verify
      space.verify_all
    end

    # Cleans up all test double state (including any methods that were
    # redefined on partial doubles). This _must_ be called after
    # each example, even if an error was raised during the example.
    def self.teardown
      space.reset_all
      self.space = ERROR_SPACE
    end

    # Adds an allowance (stub) on `subject`
    #
    # @param subject the subject to which the message will be added
    # @param message a symbol, representing the message that will be
    #                added.
    # @param opts a hash of options, :expected_from is used to set the
    #             original call site
    # @param block an optional implementation for the allowance
    #
    # @example Defines the implementation of `foo` on `bar`, using the passed block
    #   x = 0
    #   RSpec::Mocks.allow_message(bar, :foo) { x += 1 }
    def self.allow_message(subject, message, opts={}, &block)
      orig_caller = opts.fetch(:expected_from) {
        CallerFilter.first_non_rspec_line
      }
      ::RSpec::Mocks.proxy_for(subject).
        add_stub(orig_caller, message, opts, &block)
    end

    # Sets a message expectation on `subject`.
    # @param subject the subject on which the message will be expected
    # @param message a symbol, representing the message that will be
    #                expected.
    # @param opts a hash of options, :expected_from is used to set the
    #             original call site
    # @param block an optional implementation for the expectation
    #
    # @example Expect the message `foo` to receive `bar`, then call it
    #   RSpec::Mocks.expect_message(bar, :foo)
    #   bar.foo
    def self.expect_message(subject, message, opts={}, &block)
      orig_caller = opts.fetch(:expected_from) {
        CallerFilter.first_non_rspec_line
      }
      ::RSpec::Mocks.proxy_for(subject).
        add_message_expectation(orig_caller, message, opts, &block)
    end

    # @api private
    # Returns the mock proxy for the given object.
    def self.proxy_for(object)
      space.proxy_for(object)
    end

    # @api private
    # Returns the mock proxies for instances of the given class.
    def self.proxies_of(klass)
      space.proxies_of(klass)
    end

    # @api private
    # Returns the any instance recorder for the given class.
    def self.any_instance_recorder_for(klass)
      space.any_instance_recorder_for(klass)
    end

    # @private
    IGNORED_BACKTRACE_LINE = 'this backtrace line is ignored'
  end
end

