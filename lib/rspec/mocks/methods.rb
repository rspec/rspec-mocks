module RSpec
  module Mocks
    # Methods that are added to every object.
    module Methods
      # Sets and expectation that this object should receive a message before
      # the end of the example.
      #
      # @example
      #
      #     logger = double('logger')
      #     thing_that_logs = ThingThatLogs.new(logger)
      #     logger.should_receive(:log)
      #     thing_that_logs.do_something_that_logs_a_message
      def should_receive(message, opts={}, &block)
        mock_proxy = ::RSpec::Mocks.space.mock_proxy_for(self)
        mock_proxy.add_message_expectation(opts[:expected_from] || caller(1)[0], message.to_sym, opts, &block)
      end

      # Sets and expectation that this object should _not_ receive a message
      # during this example.
      def should_not_receive(message, &block)
        mock_proxy = ::RSpec::Mocks.space.mock_proxy_for(self)
        mock_proxy.add_negative_message_expectation(caller(1)[0], message.to_sym, &block)
      end

      # Tells the object to respond to the message with the specified value.
      #
      # @example
      #
      #     counter.stub(:count).and_return(37)
      #     counter.stub(:count => 37)
      #     counter.stub(:count) { 37 }
      def stub(message_or_hash, opts={}, &block)
        if Hash === message_or_hash
          message_or_hash.each {|message, value| stub(message).and_return value }
        else
          ::RSpec::Mocks.space.mock_proxy_for(self).add_stub(caller(1)[0], message_or_hash.to_sym, opts, &block)
        end
      end

      # Removes a stub. On a double, the object will no longer respond to
      # `message`. On a real object, the original method (if it exists) is
      # restored.
      #
      # This is rarely used, but can be useful when a stub is set up during a
      # shared `before` hook for the common case, but you want to replace it
      # for a special case.
      def unstub(message)
        ::RSpec::Mocks.space.mock_proxy_for(self).remove_stub(message)
      end

      def stub!(message_or_hash, opts={}, &block)
        RSpec::Mocks.warn_deprecation "\nDEPRECATION: use #stub instead of #stub!.  #{caller(0)[1]}\n"
        stub(message_or_hash, opts={}, &block)
      end

      def unstub!(message)
        RSpec::Mocks.warn_deprecation "\nDEPRECATION: use #unstub instead of #unstub!.  #{caller(0)[1]}\n"
        unstub(message)
      end

      # @overload stub_chain(method1, method2)
      # @overload stub_chain("method1.method2")
      # @overload stub_chain(method1, method_to_value_hash)
      #
      # Stubs a chain of methods.
      #
      # ## Warning:
      #
      # Chains can be arbitrarily long, which makes it quite painless to
      # violate the Law of Demeter in violent ways, so you should consider any
      # use of `stub_chain` a code smell. Even though not all code smells
      # indicate real problems (think fluent interfaces), `stub_chain` still
      # results in brittle examples.  For example, if you write
      # `foo.stub_chain(:bar, :baz => 37)` in a spec and then the
      # implementation calls `foo.baz.bar`, the stub will not work.
      #
      # @example
      #
      #     double.stub_chain("foo.bar") { :baz }
      #     double.stub_chain(:foo, :bar => :baz)
      #     double.stub_chain(:foo, :bar) { :baz }
      #
      #     # Given any of ^^ these three forms ^^:
      #     double.foo.bar # => :baz
      #
      #     # Common use in Rails/ActiveRecord:
      #     Article.stub_chain("recent.published") { [Article.new] }
      def stub_chain(*chain, &blk)
        StubChain.stub_chain_on(self, *chain, &blk)
      end

      # Tells the object to respond to all messages. If specific stub values
      # are declared, they'll work as expected. If not, the receiver is
      # returned.
      def as_null_object
        @_null_object = true
        ::RSpec::Mocks.space.mock_proxy_for(self).as_null_object
      end

      # Returns true if this object has received `as_null_object`
      def null_object?
        defined?(@_null_object)
      end

      # @private
      def received_message?(message, *args, &block)
        ::RSpec::Mocks.space.mock_proxy_for(self).received_message?(message, *args, &block)
      end
    end
  end
end

