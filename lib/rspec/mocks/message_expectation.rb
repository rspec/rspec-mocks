module RSpec
  module Mocks

    class MessageExpectation
      # @private
      attr_accessor :error_generator, :implementation
      attr_reader :message
      attr_writer :expected_received_count, :expected_from, :argument_list_matcher
      protected :expected_received_count=, :expected_from=, :error_generator, :error_generator=, :implementation=

      # @private
      def initialize(error_generator, expectation_ordering, expected_from, method_double,
                     expected_received_count=1, opts={}, &implementation)
        @error_generator = error_generator
        @error_generator.opts = opts
        @expected_from = expected_from
        @method_double = method_double
        @message = @method_double.method_name
        @actual_received_count = 0
        @expected_received_count = expected_received_count
        @argument_list_matcher = ArgumentListMatcher.new(ArgumentMatchers::AnyArgsMatcher.new)
        @order_group = expectation_ordering
        @at_least = @at_most = @exactly = nil
        @args_to_yield = []
        @failed_fast = nil
        @eval_context = nil
        @implementation = implementation
        @values_to_return = nil
      end

      # @private

      # @private
      def expected_args
        @argument_list_matcher.expected_args
      end

      # @overload and_return(value)
      # @overload and_return(first_value, second_value)
      # @overload and_return(&block)
      #
      # Tells the object to return a value when it receives the message.  Given
      # more than one value, the first value is returned the first time the
      # message is received, the second value is returned the next time, etc,
      # etc.
      #
      # If the message is received more times than there are values, the last
      # value is received for every subsequent call.
      #
      # The block format is still supported, but is unofficially deprecated in
      # favor of just passing a block to the stub method.
      #
      # @example
      #
      #   counter.stub(:count).and_return(1)
      #   counter.count # => 1
      #   counter.count # => 1
      #
      #   counter.stub(:count).and_return(1,2,3)
      #   counter.count # => 1
      #   counter.count # => 2
      #   counter.count # => 3
      #   counter.count # => 3
      #   counter.count # => 3
      #   # etc
      #
      #   # Supported, but ...
      #   counter.stub(:count).and_return { 1 }
      #   counter.count # => 1
      #
      #   # ... this is prefered
      #   counter.stub(:count) { 1 }
      #   counter.count # => 1
      def and_return(*values, &implementation)
        @expected_received_count = [@expected_received_count, values.size].max unless ignoring_args? || (@expected_received_count == 0 and @at_least)

        if implementation
          # TODO: deprecate `and_return { value }`
          @implementation = implementation
        else
          @values_to_return = values
          @implementation = build_implementation
        end
      end

      # Tells the object to delegate to the original unmodified method
      # when it receives the message.
      #
      # @note This is only available on partial mock objects.
      #
      # @example
      #
      #   counter.should_receive(:increment).and_call_original
      #   original_count = counter.count
      #   counter.increment
      #   expect(counter.count).to eq(original_count + 1)
      def and_call_original
        if @method_double.object.is_a?(RSpec::Mocks::TestDouble)
          @error_generator.raise_only_valid_on_a_partial_mock(:and_call_original)
        else
          @implementation = @method_double.original_method
        end
      end

      # @overload and_raise
      # @overload and_raise(ExceptionClass)
      # @overload and_raise(ExceptionClass, message)
      # @overload and_raise(exception_instance)
      #
      # Tells the object to raise an exception when the message is received.
      #
      # @note
      #
      #   When you pass an exception class, the MessageExpectation will raise
      #   an instance of it, creating it with `exception` and passing `message`
      #   if specified.  If the exception class initializer requires more than
      #   one parameters, you must pass in an instance and not the class,
      #   otherwise this method will raise an ArgumentError exception.
      #
      # @example
      #
      #   car.stub(:go).and_raise
      #   car.stub(:go).and_raise(OutOfGas)
      #   car.stub(:go).and_raise(OutOfGas, "At least 2 oz of gas needed to drive")
      #   car.stub(:go).and_raise(OutOfGas.new(2, :oz))
      def and_raise(exception = RuntimeError, message = nil)
        if exception.respond_to?(:exception)
          exception = message ? exception.exception(message) : exception.exception
        end

        @implementation = Proc.new { raise exception }
      end

      # @overload and_throw(symbol)
      # @overload and_throw(symbol, object)
      #
      # Tells the object to throw a symbol (with the object if that form is
      # used) when the message is received.
      #
      # @example
      #
      #   car.stub(:go).and_throw(:out_of_gas)
      #   car.stub(:go).and_throw(:out_of_gas, :level => 0.1)
      def and_throw(*args)
        @implementation = Proc.new { throw *args }
      end

      # Tells the object to yield one or more args to a block when the message
      # is received.
      #
      # @example
      #
      #   stream.stub(:open).and_yield(StringIO.new)
      def and_yield(*args, &block)
        yield @eval_context = Object.new.extend(RSpec::Mocks::InstanceExec) if block
        @args_to_yield << args
        @implementation = build_implementation
        self
      end

      # @private
      def matches?(message, *args)
        @message == message && @argument_list_matcher.args_match?(*args)
      end

      # @private
      def invoke(parent_stub, *args, &block)
        if (@expected_received_count == 0 && !@at_least) || ((@exactly || @at_most) && (@actual_received_count == @expected_received_count))
          @actual_received_count += 1
          @failed_fast = true
          @error_generator.raise_expectation_error(@message, @expected_received_count, @actual_received_count, *args)
        end

        @order_group.handle_order_constraint self

        begin
          if @implementation
            call_implementation(*args, &block)
          elsif parent_stub
            parent_stub.invoke(nil, *args, &block)
          end
        ensure
          @actual_received_count += 1
        end
      end

      # @private
      def called_max_times?
        @expected_received_count != :any &&
          !@at_least &&
          @expected_received_count > 0 &&
          @actual_received_count >= @expected_received_count
      end

      # @private
      def matches_name_but_not_args(message, *args)
        @message == message and not @argument_list_matcher.args_match?(*args)
      end

      # @private
      def verify_messages_received
        generate_error unless expected_messages_received? || failed_fast?
      rescue RSpec::Mocks::MockExpectationError => error
        error.backtrace.insert(0, @expected_from)
        Kernel::raise error
      end

      # @private
      def expected_messages_received?
        ignoring_args? || matches_exact_count? || matches_at_least_count? || matches_at_most_count?
      end

      # @private
      def ignoring_args?
        @expected_received_count == :any
      end

      # @private
      def matches_at_least_count?
        @at_least && @actual_received_count >= @expected_received_count
      end

      # @private
      def matches_at_most_count?
        @at_most && @actual_received_count <= @expected_received_count
      end

      # @private
      def matches_exact_count?
        @expected_received_count == @actual_received_count
      end

      # @private
      def similar_messages
        @similar_messages ||= []
      end

      # @private
      def advise(*args)
        similar_messages << args
      end

      # @private
      def generate_error
        if similar_messages.empty?
          @error_generator.raise_expectation_error(@message, @expected_received_count, @actual_received_count, *expected_args)
        else
          @error_generator.raise_similar_message_args_error(self, *@similar_messages)
        end
      end

      def raise_out_of_order_error
        @error_generator.raise_out_of_order_error @message
      end

      # Constrains a stub or message expectation to invocations with specific
      # arguments.
      #
      # With a stub, if the message might be received with other args as well,
      # you should stub a default value first, and then stub or mock the same
      # message using `with` to constrain to specific arguments.
      #
      # A message expectation will fail if the message is received with different
      # arguments.
      #
      # @example
      #
      #   cart.stub(:add) { :failure }
      #   cart.stub(:add).with(Book.new(:isbn => 1934356379)) { :success }
      #   cart.add(Book.new(:isbn => 1234567890))
      #   # => :failure
      #   cart.add(Book.new(:isbn => 1934356379))
      #   # => :success
      #
      #   cart.should_receive(:add).with(Book.new(:isbn => 1934356379)) { :success }
      #   cart.add(Book.new(:isbn => 1234567890))
      #   # => failed expectation
      #   cart.add(Book.new(:isbn => 1934356379))
      #   # => passes
      def with(*args, &block)
        @implementation = block if block_given? unless args.empty?
        @argument_list_matcher = ArgumentListMatcher.new(*args, &block)
        self
      end

      # Constrain a message expectation to be received a specific number of
      # times.
      #
      # @example
      #
      #   dealer.should_receive(:deal_card).exactly(10).times
      def exactly(n, &block)
        @implementation = block if block
        set_expected_received_count :exactly, n
        self
      end

      # Constrain a message expectation to be received at least a specific
      # number of times.
      #
      # @example
      #
      #   dealer.should_receive(:deal_card).at_least(9).times
      def at_least(n, &block)
        @implementation = block if block
        set_expected_received_count :at_least, n
        self
      end

      # Constrain a message expectation to be received at most a specific
      # number of times.
      #
      # @example
      #
      #   dealer.should_receive(:deal_card).at_most(10).times
      def at_most(n, &block)
        @implementation = block if block
        set_expected_received_count :at_most, n
        self
      end

      # Syntactic sugar for `exactly`, `at_least` and `at_most`
      #
      # @example
      #
      #   dealer.should_receive(:deal_card).exactly(10).times
      #   dealer.should_receive(:deal_card).at_least(10).times
      #   dealer.should_receive(:deal_card).at_most(10).times
      def times(&block)
        @implementation = block if block
        self
      end


      # Allows an expected message to be received any number of times.
      def any_number_of_times(&block)
        @implementation = block if block
        @expected_received_count = :any
        self
      end

      # Expect a message not to be received at all.
      #
      # @example
      #
      #   car.should_receive(:stop).never
      def never
        @expected_received_count = 0
        self
      end

      # Expect a message to be received exactly one time.
      #
      # @example
      #
      #   car.should_receive(:go).once
      def once(&block)
        @implementation = block if block
        set_expected_received_count :exactly, 1
        self
      end

      # Expect a message to be received exactly two times.
      #
      # @example
      #
      #   car.should_receive(:go).twice
      def twice(&block)
        @implementation = block if block
        set_expected_received_count :exactly, 2
        self
      end

      # Expect messages to be received in a specific order.
      #
      # @example
      #
      #   api.should_receive(:prepare).ordered
      #   api.should_receive(:run).ordered
      #   api.should_receive(:finish).ordered
      def ordered(&block)
        @implementation = block if block
        @order_group.register(self)
        @ordered = true
        self
      end

      # @private
      def negative_expectation_for?(message)
        return false
      end

      # @private
      def actual_received_count_matters?
        @at_least || @at_most || @exactly
      end

      # @private
      def increase_actual_received_count!
        @actual_received_count += 1
      end

      protected

      def call_implementation(*args, &block)
        if @implementation.arity.zero?
          @implementation.call(&block)
        else
          @implementation.call(*args, &block)
        end
      end

      def failed_fast?
        @failed_fast
      end

      def set_expected_received_count(relativity, n)
        @at_least = (relativity == :at_least)
        @at_most  = (relativity == :at_most)
        @exactly  = (relativity == :exactly)
        @expected_received_count = case n
                                   when Numeric then n
                                   when :once   then 1
                                   when :twice  then 2
                                   end
      end

      private

      def build_implementation
        Implementation.new(
          @values_to_return, @args_to_yield,
          @eval_context, @error_generator
        ).method(:call)
      end
    end

    # @private
    class NegativeMessageExpectation < MessageExpectation
      # @private
      def initialize(error_generator, expectation_ordering, expected_from, method_double, &implementation)
        super(error_generator, expectation_ordering, expected_from, method_double, 0, {}, &implementation)
      end

      def and_return(*)
        # no-op
        # @deprecated and_return is not supported with negative message expectations.
        RSpec::Mocks.warn_deprecation <<-MSG

DEPRECATION: `and_return` with `should_not_receive` is deprecated. Called from #{caller(0)[1]}
MSG
      end

      # @private
      def negative_expectation_for?(message)
        return @message == message
      end
    end

    # Represents a configured implementation. Takes into account
    # `and_return` and `and_yield` instructions.
    # @private
    class Implementation
      def initialize(values_to_return, args_to_yield, eval_context, error_generator)
        @values_to_return = values_to_return
        @args_to_yield = args_to_yield
        @eval_context = eval_context
        @error_generator = error_generator
      end

      def call(&block)
        default_return_value = perform_yield(&block)
        return default_return_value unless @values_to_return

        if @values_to_return.size > 1
          @values_to_return.shift
        else
          @values_to_return.first
        end
      end

      def perform_yield(&block)
        return if @args_to_yield.empty? && @eval_context.nil?

        @error_generator.raise_missing_block_error @args_to_yield unless block
        value = nil
        @args_to_yield.each do |args|
          if block.arity > -1 && args.length != block.arity
            @error_generator.raise_wrong_arity_error args, block.arity
          end
          value = @eval_context ? @eval_context.instance_exec(*args, &block) : block.call(*args)
        end
        value
      end
    end
  end
end
