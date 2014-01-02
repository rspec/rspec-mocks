Feature: Test::Unit integration

  rspec-mocks is a stand-alone gem that can be used without the rest of
  RSpec. If you like the way Test::Unit (or MiniTest) organizes tests, but
  prefer RSpec's approach to mocking/stubbing/doubles etc, you can have both.

  The one downside is that failures are reported as errors with MiniTest.

  Scenario: use rspec/mocks with Test::Unit
    Given a file named "rspec_mocks_test.rb" with:
      """ruby
      require 'test/unit'
      require 'rspec/mocks'

      class RSpecMocksTest < Test::Unit::TestCase
        include RSpec::Mocks::ExampleMethods

        def setup
          RSpec::Mocks.setup
        end

        def teardown
          RSpec::Mocks.verify
        ensure
          RSpec::Mocks.teardown
        end

        def test_passing_positive_expectation
          obj = Object.new
          expect(obj).to receive(:message)
          obj.message
        end

        def test_failing_positive_expectation
          obj = Object.new
          expect(obj).to receive(:message)
          obj.message
        end

        def test_passing_negative_expectation
          obj = Object.new
          expect(obj).to_not receive(:message)
        end

        def test_failing_negative_expectation
          obj = Object.new
          expect(obj).to_not receive(:message)
          obj.message
        end
      end
      """
     When I run `ruby rspec_mocks_test.rb`
     Then the output should contain "4 tests, 0 assertions, 0 failures, 1 errors" or "4 tests, 0 assertions, 1 failures, 0 errors"
     And the output should contain "expected: 0 times with any arguments"
