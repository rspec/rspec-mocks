module RSpec
  module Mocks
    # Support for `exclude_stubbed_classes_from_subclasses` configuration.
    #
    # @private
    class ExcludeStubbedClassesFromSubclasses
      class << self
        def enable!
          return unless RUBY_VERSION >= "3.1"
          return if Class.respond_to?(:subclasses_with_rspec_mocks)

          Class.class_eval do
            def subclasses_with_rspec_mocks
              subclasses_without_rspec_mocks - RSpec::Mocks::ExcludeStubbedClassesFromSubclasses.excluded_subclasses
            end

            alias subclasses_without_rspec_mocks subclasses
            alias subclasses subclasses_with_rspec_mocks
          end
        end

        def disable!
          @excluded_subclasses = []

          if Class.respond_to?(:subclasses_with_rspec_mocks)
            Class.class_eval do
              undef subclasses_with_rspec_mocks
              alias subclasses subclasses_without_rspec_mocks
              undef subclasses_without_rspec_mocks
            end
          end
        end

        def excluded_subclasses
          require 'weakref' unless defined?(::WeakRef)

          @excluded_subclasses ||= []
          @excluded_subclasses.select(&:weakref_alive?).map do |ref|
            begin
              ref.__getobj__
            rescue ::WeakRef::RefError
              nil
            end
          end.compact
        end

        def exclude_subclass(constant)
          require 'weakref' unless defined?(::WeakRef)

          @excluded_subclasses ||= []
          @excluded_subclasses << ::WeakRef.new(constant)
        end
      end
    end
  end
end
