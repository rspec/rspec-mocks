RSpec::Support.require_rspec_support 'mutex'

module RSpec
  module Mocks
    module ReceivedCount
      # @!group Constraining Receive Counts
      # fixme: are all those needed?
      def initialize(error_generator, expectation_ordering, expected_from, method_double,
                     type=:expectation, opts={}, &implementation_block)
        @actual_received_count = 0
        @actual_received_count_write_mutex = Support::Mutex.new
        @expected_received_count = type == :expectation ? 1 : :any

        # fixme: seems odd. can be a strategy?
        @at_least = @at_most = @exactly = nil
        super
      end

      # FIXME: change return type to including class

      # FIXME: mutually exclusive with never, at least, at most and direct exact counters
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

        # fixme: not necessarily receive
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

      # TODO: docs

      # fixme: are all those `receive` specific?
      # what is actually needed for general usage?
      # public: exactly at_least at_most once twice thrice never times
      # internal: max_times? expected actual
      def matches_count?
        matches_exact_count? || matches_at_least_count? || matches_at_most_count?
      end

      # fixme: extract the logic behind the consumers of this method here
      def expectation_count_type
        return :at_least if @at_least
        return :at_most if @at_most
        nil
      end

      def negative?
        @expected_received_count == 0 && !@at_least
      end

      def called_max_times?
        @expected_received_count != :any &&
          !@at_least &&
          @expected_received_count > 0 &&
          @actual_received_count >= @expected_received_count
      end

      # FIXME: confusing name (for generic application)
      def ignoring_args?
        @expected_received_count == :any
      end

      def actual_received_count_matters?
        @at_least || @at_most || @exactly
      end

      def exactly_or_at_most?
        @exactly || @at_most
      end

      attr_reader :expected_received_count, :actual_received_count

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

      def matches_at_least_count?
        @at_least && @actual_received_count >= @expected_received_count
      end

      def matches_at_most_count?
        @at_most && @actual_received_count <= @expected_received_count
      end

      def matches_exact_count?
        @expected_received_count == @actual_received_count
      end
    end
  end
end
