module RSpec
  module Mocks
    UnsupportedMatcherError  = Class.new(StandardError)
    NegationUnsupportedError = Class.new(StandardError)

    class TargetBase
      def initialize(target)
        @target = target
      end

      def self.delegate_to(matcher_method, options = {})
        method_name = options.fetch(:from) { :to }
        define_method(method_name) do |matcher, &block|
          unless Matchers::Receive === matcher || Matchers::ReceiveMessages === matcher
            raise_unsupported_matcher(:to, matcher)
          end

          matcher.__send__(matcher_method, @target, &block)
        end
      end

      def self.disallow_negation(method_name)
        define_method(method_name) do |matcher, *args|
          raise_negation_unsupported(method_name, matcher)
        end
      end

    private

      def raise_unsupported_matcher(method_name, matcher)
        raise UnsupportedMatcherError,
          "only the `receive` or `receive_messages` matchers are supported " +
          "with `#{expression}(...).#{method_name}`, but you have provided: #{matcher}"
      end

      def raise_negation_unsupported(method_name, matcher)
        raise NegationUnsupportedError,
          "`#{expression}(...).#{method_name} #{matcher.name}` is not supported since it " +
          "doesn't really make sense. What would it even mean?"
      end

      def expression
        self.class::EXPRESSION
      end
    end

    class AllowanceTarget < TargetBase
      EXPRESSION = :allow
      delegate_to :setup_allowance
      disallow_negation :not_to
      disallow_negation :to_not
    end

    class ExpectationTarget < TargetBase
      EXPRESSION = :expect
      delegate_to :setup_expectation
      delegate_to :setup_negative_expectation, :from => :not_to
      delegate_to :setup_negative_expectation, :from => :to_not
    end

    class AnyInstanceAllowanceTarget < TargetBase
      EXPRESSION = :allow_any_instance_of
      delegate_to :setup_any_instance_allowance
      disallow_negation :not_to
      disallow_negation :to_not
    end

    class AnyInstanceExpectationTarget < TargetBase
      EXPRESSION = :expect_any_instance_of
      delegate_to :setup_any_instance_expectation
      delegate_to :setup_any_instance_negative_expectation, :from => :not_to
      delegate_to :setup_any_instance_negative_expectation, :from => :to_not
    end
  end
end

