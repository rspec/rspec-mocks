Feature: the expect syntax for message expectations

  Use `expect(receiver).to receive(:message)` to set an expectation that
  `receiver` should receive the message `:message` before the example is
  completed.

  Scenario: expect a message
    Given a file named "spec/account_spec.rb" with:
      """ruby
      require "spec_helper"
      require "account"

      describe Account do
        context "when closed" do
          it "logs an account closed message" do
            logger = double("logger")
            account = Account.new
            account.logger = logger

            expect(logger).to receive(:account_closed)

            account.close
          end
        end
      end
      """
    And a file named "lib/account.rb" with:
      """ruby
      class Account
        attr_accessor :logger

        def close
          logger.account_closed
        end
      end
      """
    And a file named "spec/spec_helper.rb" with:
    """ruby
    RSpec.configure do |config|
      config.mock_with :rspec do |mocks|
        mocks.syntax = :expect
      end
    end
    """
    When I run `rspec spec/account_spec.rb`
    Then the output should contain "1 example, 0 failures"

  Scenario: expect a message with an argument
    Given a file named "spec/account_spec.rb" with:
      """ruby
      require "account"
      require "spec_helper"

      describe Account do
        context "when closed" do
          it "logs an account closed message" do
            logger = double("logger")
            account = Account.new
            account.logger = logger

            expect(logger).to receive(:account_closed).with(account)

            account.close
          end
        end
      end
      """
    And a file named "lib/account.rb" with:
      """ruby
      class Account
        attr_accessor :logger

        def close
          logger.account_closed(self)
        end
      end
      """
    And a file named "spec/spec_helper.rb" with:
    """ruby
    RSpec.configure do |config|
      config.mock_with :rspec do |mocks|
        mocks.syntax = :expect
      end
    end
    """
    When I run `rspec spec/account_spec.rb`
    Then the output should contain "1 example, 0 failures"

  Scenario: provide a return value
    Given a file named "spec/message_expectation_spec.rb" with:
      """ruby
      require "spec_helper"
      describe "a message expectation" do
        context "with a return value" do
          context "specified in a block" do
            it "returns the specified value" do
              receiver = double("receiver")
              expect(receiver).to receive(:message) { :return_value }
              receiver.message.should eq(:return_value)
            end
          end

          context "specified with and_return" do
            it "returns the specified value" do
              receiver = double("receiver")
              expect(receiver).to receive(:message).and_return(:return_value)
              receiver.message.should eq(:return_value)
            end
          end
        end
      end
      """
    And a file named "spec/spec_helper.rb" with:
      """ruby
      RSpec.configure do |config|
        config.mock_with :rspec do |mocks|
          mocks.syntax = :expect
        end
      end
      """
    When I run `rspec spec/message_expectation_spec.rb`
    Then the output should contain "2 examples, 0 failures"

  Scenario: expect a specific number of calls
    Given a file named "spec/message_count_spec.rb" with:
      """ruby
      require "spec_helper"
      describe "a message expectation with a count" do
        it "passes if the expected number of calls happen" do
          receiver = "hi"
          expect(receiver).to receive(:length).exactly(3).times

          3.times { receiver.length }
        end
      end
      """
    And a file named "spec/spec_helper.rb" with:
      """ruby
      RSpec.configure do |config|
        config.mock_with :rspec do |mocks|
          mocks.syntax = :expect
        end
      end
      """
    When I run `rspec spec/message_count_spec.rb`
    Then the output should contain "1 example, 0 failures"
