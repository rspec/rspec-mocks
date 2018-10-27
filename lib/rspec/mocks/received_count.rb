module RSpec
  module Mocks
    module ReceivedCount
      # @!group Constraining Receive Counts
      def initialize(error_generator, expectation_ordering, expected_from, method_double,
                     type=:expectation, opts={}, &implementation_block)
        @actual_received_count = 0
        @actual_received_count_write_mutex = Support::Mutex.new
        @expected_received_count = type == :expectation ? 1 : :any
        @at_least = @at_most = @exactly = nil
        super
      end

      # Constrain a message expectation to be received a specific number of
      # times.
      #
      # @return [MessageExpectation] self, to support further chaining.
      # @example
      #   expect(dealer).to receive(:deal_card).exactly(10).times
      def exactly(n, &block)
        raise_already_invoked_error_if_necessary(__method__)
        self.inner_implementation_action = block
        set_expected_received_count :exactly, n
        self
      end

      # Constrain a message expectation to be received at least a specific
      # number of times.
      #
      # @return [MessageExpectation] self, to support further chaining.
      # @example
      #   expect(dealer).to receive(:deal_card).at_least(9).times
      def at_least(n, &block)
        raise_already_invoked_error_if_necessary(__method__)
        set_expected_received_count :at_least, n

        if n == 0
          raise "at_least(0) has been removed, use allow(...).to receive(:message) instead"
        end

        self.inner_implementation_action = block

        self
      end

      # Constrain a message expectation to be received at most a specific
      # number of times.
      #
      # @return [MessageExpectation] self, to support further chaining.
      # @example
      #   expect(dealer).to receive(:deal_card).at_most(10).times
      def at_most(n, &block)
        raise_already_invoked_error_if_necessary(__method__)
        self.inner_implementation_action = block
        set_expected_received_count :at_most, n
        self
      end

      # Syntactic sugar for `exactly`, `at_least` and `at_most`
      #
      # @return [MessageExpectation] self, to support further chaining.
      # @example
      #   expect(dealer).to receive(:deal_card).exactly(10).times
      #   expect(dealer).to receive(:deal_card).at_least(10).times
      #   expect(dealer).to receive(:deal_card).at_most(10).times
      def times(&block)
        self.inner_implementation_action = block
        self
      end

      # Expect a message not to be received at all.
      #
      # @return [MessageExpectation] self, to support further chaining.
      # @example
      #   expect(car).to receive(:stop).never
      def never
        error_generator.raise_double_negation_error("expect(obj)") if negative?
        @expected_received_count = 0
        self
      end

      # Expect a message to be received exactly one time.
      #
      # @return [MessageExpectation] self, to support further chaining.
      # @example
      #   expect(car).to receive(:go).once
      def once(&block)
        self.inner_implementation_action = block
        set_expected_received_count :exactly, 1
        self
      end

      # Expect a message to be received exactly two times.
      #
      # @return [MessageExpectation] self, to support further chaining.
      # @example
      #   expect(car).to receive(:go).twice
      def twice(&block)
        self.inner_implementation_action = block
        set_expected_received_count :exactly, 2
        self
      end

      # Expect a message to be received exactly three times.
      #
      # @return [MessageExpectation] self, to support further chaining.
      # @example
      #   expect(car).to receive(:go).thrice
      def thrice(&block)
        self.inner_implementation_action = block
        set_expected_received_count :exactly, 3
        self
      end
      # @!endgroup

      def increase_actual_received_count!(increment = 1)
        @actual_received_count_write_mutex.synchronize do
          @actual_received_count += increment
        end
      end

    private

      def set_expected_received_count(relativity, n)
        raise "`count` is not supported with negative message expectations" if negative?
        @at_least = (relativity == :at_least)
        @at_most  = (relativity == :at_most)
        @exactly  = (relativity == :exactly)
        @expected_received_count = case n
                                   when Numeric then n
                                   when :once   then 1
                                   when :twice  then 2
                                   when :thrice then 3
                                   end
      end

    end
  end
end
