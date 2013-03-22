require 'spec_helper'

module RSpec
  module Mocks
    describe HaveReceived do
      context "matches?" do
        it "returns true when an expectation is met" do
          double = double_with_met_expectation(:expected_method)
          result = have_received(:expected_method).matches?(double)
          expect(result).to be_true
        end

        it "returns false when the expectation is not met" do
          double = double_with_unmet_expectation(:expected_method)
          result = have_received(:expected_method).matches?(double)
          expect(result).to be_false
        end
      end

      context "does_not_match?" do
        it "returns true when the method is never called" do
          double = double_with_unmet_expectation(:expected_method)
          result = have_received(:expected_method).does_not_match?(double)
          expect(result).to be_true
        end

        it "returns false when the method is called" do
          double = double_with_met_expectation(:expected_method)
          result = have_received(:expected_method).does_not_match?(double)
          expect(result).to be_false
        end
      end

      context "failure_message" do
        it "includes the failed expectation" do
          double = double_with_unmet_expectation(:expected_method)
          matcher = have_received(:expected_method)
          matcher.matches?(double)
          message = matcher.failure_message
          expect(message).to include('expected: 1 time')
        end
      end

      context "negative_failure_message" do
        it "includes the failed expectation" do
          double = double_with_met_expectation(:expected_method)
          matcher = have_received(:expected_method)
          matcher.does_not_match?(double)
          message = matcher.negative_failure_message
          expect(message).to include('expected: 0 times')
          expect(message).to include('received: 1 time')
        end
      end

      context "with" do
        it "matches when the given arguments match" do
          double =
            double_with_met_expectation(:expected_method, :expected, :args)
          matcher = have_received(:expected_method).with(:expected, :args)
          result = matcher.matches?(double)
          expect(result).to be_true
        end

        it "doesn't match when the given arguments don't match" do
          double = double_with_met_expectation(:expected_method, :unexpected)
          matcher = have_received(:expected_method).with(:expected, :args)
          result = matcher.matches?(double)
          expect(result).to be_false
        end
      end

      context "count constraint" do
        HaveReceived::CONSTRAINTS.each do |constraint|
          it "delegates #{constraint} to the expectation" do
            double = double('double', some_method: true)
            expectation =
              double('message_expectation', expected_messages_received?: true)
            double.
              should_receive(:__mock_expectation).
              with(:some_method).
              and_yield(expectation).
              and_return(expectation)
            expectation.should_receive(constraint).with(:expected, :args)

            have_received(:some_method).
              send(constraint, :expected, :args).
              matches?(double)
          end
        end
      end

      def double_with_met_expectation(method_name, *args)
        double = double_with_unmet_expectation(method_name)
        double.send(method_name, *args)
        double
      end

      def double_with_unmet_expectation(method_name)
        double('double', method_name => true)
      end
    end
  end
end
