# This cannot take advantage of our relative requires, since this file is a
# dependency of `rspec/mocks/argument_list_matcher.rb`. See comment there for
# details.
require 'rspec/support/matcher_definition'

module RSpec
  module Mocks
    # ArgumentMatchers are placeholders that you can include in message
    # expectations to match arguments against a broader check than simple
    # equality.
    #
    # With the exception of `any_args` and `no_args`, they all match against
    # the arg in same position in the argument list.
    #
    # @see ArgumentListMatcher
    module ArgumentMatchers
      # Matches any args at all. Supports a more explicit variation of
      # `expect(object).to receive(:message)`
      #
      # @example
      #
      #   expect(object).to receive(:message).with(any_args)
      def any_args
        AnyArgsMatcher.new
      end

      # Matches any argument at all.
      #
      # @example
      #
      #   expect(object).to receive(:message).with(anything)
      def anything
        AnyArgMatcher.new
      end

      # Matches no arguments.
      #
      # @example
      #
      #   expect(object).to receive(:message).with(no_args)
      def no_args
        NoArgsMatcher.new
      end

      # Matches if the actual argument responds to the specified messages.
      #
      # @example
      #
      #   expect(object).to receive(:message).with(duck_type(:hello))
      #   expect(object).to receive(:message).with(duck_type(:hello, :goodbye))
      def duck_type(*args)
        DuckTypeMatcher.new(*args)
      end

      # Matches a boolean value.
      #
      # @example
      #
      #   expect(object).to receive(:message).with(boolean())
      def boolean
        BooleanMatcher.new
      end

      # Matches a hash that includes the specified key(s) or key/value pairs.
      # Ignores any additional keys.
      #
      # @example
      #
      #   expect(object).to receive(:message).with(hash_including(:key => val))
      #   expect(object).to receive(:message).with(hash_including(:key))
      #   expect(object).to receive(:message).with(hash_including(:key, :key2 => val2))
      def hash_including(*args)
        HashIncludingMatcher.new(ArgumentMatchers.anythingize_lonely_keys(*args))
      end

      # Matches an array that includes the specified items at least once.
      # Ignores duplicates and additional values
      #
      # @example
      #
      #   expect(object).to receive(:message).with(array_including(1,2,3))
      #   expect(object).to receive(:message).with(array_including([1,2,3]))
      def array_including(*args)
        actually_an_array = Array === args.first && args.count == 1 ? args.first : args
        ArrayIncludingMatcher.new(actually_an_array)
      end

      # Matches a hash that doesn't include the specified key(s) or key/value.
      #
      # @example
      #
      #   expect(object).to receive(:message).with(hash_excluding(:key => val))
      #   expect(object).to receive(:message).with(hash_excluding(:key))
      #   expect(object).to receive(:message).with(hash_excluding(:key, :key2 => :val2))
      def hash_excluding(*args)
        HashExcludingMatcher.new(ArgumentMatchers.anythingize_lonely_keys(*args))
      end

      alias_method :hash_not_including, :hash_excluding

      # Matches if `arg.instance_of?(klass)`
      #
      # @example
      #
      #   expect(object).to receive(:message).with(instance_of(Thing))
      def instance_of(klass)
        InstanceOf.new(klass)
      end

      alias_method :an_instance_of, :instance_of

      # Matches if `arg.kind_of?(klass)`
      # @example
      #
      #   expect(object).to receive(:message).with(kind_of(Thing))
      def kind_of(klass)
        KindOf.new(klass)
      end

      alias_method :a_kind_of, :kind_of

      # @private
      def self.anythingize_lonely_keys(*args)
        hash = args.last.class == Hash ? args.delete_at(-1) : {}
        args.each { | arg | hash[arg] = AnyArgMatcher.new }
        hash
      end

      # @private
      class AnyArgsMatcher
        def description
          "any args"
        end
      end

      # @private
      class AnyArgMatcher
        def ===(_other)
          true
        end

        def description
          "anything"
        end
      end

      # @private
      class NoArgsMatcher
        def description
          "no args"
        end
      end

      # @private
      class BooleanMatcher
        def ===(value)
          true == value || false == value
        end

        def description
          "boolean"
        end
      end

      # @private
      class BaseHashMatcher
        def initialize(expected)
          @expected = expected
        end

        def ===(predicate, actual)
          @expected.__send__(predicate) do |k, v|
            actual.key?(k) && Support::FuzzyMatcher.values_match?(v, actual[k])
          end
        rescue NoMethodError
          false
        end

        def description(name)
          "#{name}(#{@expected.inspect.sub(/^\{/, "").sub(/\}$/, "")})"
        end
      end

      # @private
      class HashIncludingMatcher < BaseHashMatcher
        def ===(actual)
          super(:all?, actual)
        end

        def description
          super("hash_including")
        end
      end

      # @private
      class HashExcludingMatcher < BaseHashMatcher
        def ===(actual)
          super(:none?, actual)
        end

        def description
          super("hash_not_including")
        end
      end

      # @private
      class ArrayIncludingMatcher
        def initialize(expected)
          @expected = expected
        end

        def ===(actual)
          Set.new(actual).superset?(Set.new(@expected))
        end

        def description
          "array_including(#{@expected.join(", ")})"
        end
      end

      # @private
      class DuckTypeMatcher
        def initialize(*methods_to_respond_to)
          @methods_to_respond_to = methods_to_respond_to
        end

        def ===(value)
          @methods_to_respond_to.all? { |message| value.respond_to?(message) }
        end

        def description
          "duck_type(#{@methods_to_respond_to.map(&:inspect).join(', ')})"
        end
      end

      # @private
      class InstanceOf
        def initialize(klass)
          @klass = klass
        end

        def ===(actual)
          actual.instance_of?(@klass)
        end

        def description
          "an_instance_of(#{@klass.name})"
        end
      end

      # @private
      class KindOf
        def initialize(klass)
          @klass = klass
        end

        def ===(actual)
          actual.kind_of?(@klass)
        end

        def description
          "kind of #{@klass.name}"
        end
      end

      matcher_namespace = name + '::'
      ::RSpec::Support.register_matcher_definition do |object|
        # This is the best we have for now. We should tag all of our matchers
        # with a module or something so we can test for it directly.
        #
        # (Note Module#parent in ActiveSupport is defined in a similar way.)
        begin
          object.class.name.include?(matcher_namespace)
        rescue NoMethodError
          # Some objects, like BasicObject, don't implemented standard
          # reflection methods.
          false
        end
      end
    end
  end
end
