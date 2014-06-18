module RSpec
  module Mocks
    # Implements the methods needed for a pure test double.  RSpec::Mocks::Double
    # includes this module, and it is provided for cases where you want a
    # pure test double without subclassing RSpec::Mocks::Double.
    module TestDouble
      # Creates a new test double with a `name` (that will be used in error
      # messages only)
      def initialize(name=nil, stubs={})
        @__expired = false
        if Hash === name && stubs.empty?
          stubs = name
          @name = nil
        else
          @name = name
        end
        assign_stubs(stubs)
      end

      # Tells the object to respond to all messages. If specific stub values
      # are declared, they'll work as expected. If not, the receiver is
      # returned.
      def as_null_object
        __mock_proxy.as_null_object
      end

      # Returns true if this object has received `as_null_object`
      def null_object?
        __mock_proxy.null_object?
      end

      # This allows for comparing the mock to other objects that proxy such as
      # ActiveRecords belongs_to proxy objects. By making the other object run
      # the comparison, we're sure the call gets delegated to the proxy
      # target.
      def ==(other)
        other == __mock_proxy
      end

      # @private
      def inspect
        "#<#{self.class}:#{sprintf '0x%x', self.object_id} @name=#{@name.inspect}>"
      end

      # @private
      def to_s
        inspect.gsub('<','[').gsub('>',']')
      end

      # @private
      def respond_to?(message, incl_private=false)
        __mock_proxy.null_object? ? true : super
      end

      # @private
      def __build_mock_proxy_unless_expired(order_group)
        __raise_expired_error or __build_mock_proxy(order_group)
      end

      # @private
      def __disallow_further_usage!
        @__expired = true
      end

      # Override for default freeze implementation to prevent freezing of test
      # doubles.
      def freeze
        RSpec.warn_with("WARNING: you attempted to freeze a test double. This is explicitly a no-op as freezing doubles can lead to undesired behaviour when resetting tests.")
      end

    private

      def method_missing(message, *args, &block)
        proxy = __mock_proxy
        proxy.record_message_received(message, *args, &block)

        if proxy.null_object?
          case message
          when :to_int        then return 0
          when :to_a, :to_ary then return nil
          when :to_str        then return to_s
          else return self
          end
        end

        # Defined private and protected methods will still trigger `method_missing`
        # when called publicly. We want ruby's method visibility error to get raised,
        # so we simply delegate to `super` in that case.
        # ...well, we would delegate to `super`, but there's a JRuby
        # bug, so we raise our own visibility error instead:
        # https://github.com/jruby/jruby/issues/1398
        visibility = proxy.visibility_for(message)
        if visibility == :private || visibility == :protected
          ErrorGenerator.new(self, @name).raise_non_public_error(
            message, visibility
          )
        end

        # Required wrapping doubles in an Array on Ruby 1.9.2
        raise NoMethodError if [:to_a, :to_ary].include? message
        proxy.raise_unexpected_message_error(message, *args)
      end

      def assign_stubs(stubs)
        stubs.each_pair do |message, response|
          __mock_proxy.add_simple_stub(message, response)
        end
      end

      def __mock_proxy
        ::RSpec::Mocks.space.proxy_for(self)
      end

      def __build_mock_proxy(order_group)
        TestDoubleProxy.new(self, order_group, @name)
      end

      def __raise_expired_error
        return false unless @__expired
        ErrorGenerator.new(self, @name).raise_expired_test_double_error
      end
    end

    # A generic test double object. `double`, `instance_double` and friends
    # return an instance of this.
    class Double
      include TestDouble
    end
  end
end
