module RSpec
  module Mocks
    # Implements the methods needed for a pure test double.  RSpec::Mocks::Mock
    # includes this module, and it is provided for cases where you want a
    # pure test double without subclassing RSpec::Mocks::Mock.
    module TestDouble
      # Extends the TestDouble module onto the given object and
      # initializes it as a test double.
      #
      # @example
      #
      #   module = Module.new
      #   RSpec::Mocks::TestDouble.extend_onto(module, "MyMixin", :foo => "bar")
      #   module.foo  #=> "bar"
      def self.extend_onto(object, name=nil, stubs={})
        object.extend self
        object.send(:__initialize_as_test_double, name, stubs)
      end

      # Creates a new test double with a `name` (that will be used in error
      # messages only)
      def initialize(name=nil, stubs={})
        __initialize_as_test_double(name, stubs)
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

      alias_method :to_str, :to_s

      # @private
      def respond_to?(message, incl_private=false)
        __mock_proxy.null_object? ? true : super
      end

      # @private
      def __build_mock_proxy
        Proxy.new(self, @name)
      end

    private

      def __initialize_as_test_double(name=nil, stubs={})
        if Hash === name && stubs.empty?
          stubs = name
          @name = nil
        else
          @name = name
        end
        assign_stubs(stubs)
      end

      def method_missing(message, *args, &block)
        if __mock_proxy.null_object?
          case message
          when :to_int        then return 0
          when :to_a, :to_ary then return nil
          end
        end
        __mock_proxy.record_message_received(message, *args, &block)

        begin
          __mock_proxy.null_object? ? self : super
        rescue NameError
          # Required wrapping doubles in an Array on Ruby 1.9.2
          raise NoMethodError if [:to_a, :to_ary].include? message
          __mock_proxy.raise_unexpected_message_error(message, *args)
        end
      end

      def assign_stubs(stubs)
        stubs.each_pair do |message, response|
          __mock_proxy.add_simple_stub(message, response)
        end
      end

      def __mock_proxy
        ::RSpec::Mocks.proxy_for(self)
      end
    end
  end
end
