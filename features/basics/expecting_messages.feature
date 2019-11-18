Feature: Expecting messages

  Use `expect(...).to receive(...)` to expect a message on a [test double](./test-doubles). Unfulfilled
  message expectations trigger failures when the example completes. You can also use
  `expect(...).not_to receive(...)` to set a negative message expectation.

  Note: Composing expectations as shown here will only work if you are using rspec-expectations.

  Scenario: Failing positive message expectation
    Given a file named "unfulfilled_message_expectation_spec.rb" with:
      """ruby
      RSpec.describe "An unfulfilled positive message expectation" do
        it "triggers a failure" do
          dbl = double("Some Collaborator")
          expect(dbl).to receive(:foo)
        end
      end
      """
     When I run `rspec unfulfilled_message_expectation_spec.rb`
     Then it should fail with:
      """
        1) An unfulfilled positive message expectation triggers a failure
           Failure/Error: expect(dbl).to receive(:foo)

             (Double "Some Collaborator").foo(*(any args))
                 expected: 1 time with any arguments
                 received: 0 times with any arguments
      """

  Scenario: Passing positive message expectation
    Given a file named "fulfilled_message_expectation_spec.rb" with:
      """ruby
      RSpec.describe "A fulfilled positive message expectation" do
        it "passes" do
          dbl = double("Some Collaborator")
          expect(dbl).to receive(:foo)
          dbl.foo
        end
      end
      """
     When I run `rspec fulfilled_message_expectation_spec.rb`
     Then the examples should all pass

  Scenario: Failing negative message expectation
    Given a file named "negative_message_expectation_spec.rb" with:
      """ruby
      RSpec.describe "A negative message expectation" do
        it "fails when the message is received" do
          dbl = double("Some Collaborator").as_null_object
          expect(dbl).not_to receive(:foo)
          dbl.foo
        end
      end
      """
     When I run `rspec negative_message_expectation_spec.rb`
     Then it should fail with:
      """
        1) A negative message expectation fails when the message is received
           Failure/Error: dbl.foo

             (Double "Some Collaborator").foo(no args)
                 expected: 0 times with any arguments
                 received: 1 time
      """

  Scenario: Passing negative message expectation
    Given a file named "negative_message_expectation_spec.rb" with:
      """ruby
      RSpec.describe "A negative message expectation" do
        it "passes if the message is never received" do
          dbl = double("Some Collaborator").as_null_object
          expect(dbl).not_to receive(:foo)
        end
      end
      """
     When I run `rspec negative_message_expectation_spec.rb`
     Then the examples should all pass

  Scenario: Composing expectations with `.and`
    Given a file named "and_expectations_spec.rb" with:
      """ruby
      RSpec.describe "Composed expectations with `.and`" do
        let(:dbl) { double("Some Collaborator") }

        before do
          allow(dbl).to receive_messages(foo: nil, bar: nil)
          expect(dbl).to receive(:foo)
                     .and receive(:bar)
        end

        it "passes if both messages received" do
          dbl.foo
          dbl.bar
        end

        it "fails if only first message received" do
          dbl.foo
        end

        it "fails if only second message received" do
          dbl.bar
        end
      end
      """
    When I run `rspec and_expectations_spec.rb`
    Then it should fail with the following output:
      | 3 examples, 2 failures                                                                              |
      |                                                                                                     |
      |  1) Composed expectations with `.and` fails if only first message received                          |
      |     Failure/Error:                                                                                  |
      |       expect(dbl).to receive(:foo)                                                                  |
      |                  .and receive(:bar)                                                                 |
      |                                                                                                     |
      |       (Double "Some Collaborator").bar(*(any args))                                                 |
      |           expected: 1 time with any arguments                                                       |
      |           received: 0 times with any arguments                                                      |
      |                                                                                                     |
      |  2) Composed expectations with `.and` fails if only second message received                         |
      |     Failure/Error:                                                                                  |
      |       expect(dbl).to receive(:foo)                                                                  |
      |                  .and receive(:bar)                                                                 |
      |                                                                                                     |
      |       (Double "Some Collaborator").foo(*(any args))                                                 |
      |           expected: 1 time with any arguments                                                       |
      |           received: 0 times with any arguments                                                      |
      |                                                                                                     |

  Scenario: Composing expectations with `.or`
    Given a file named "or_expectations_spec.rb" with:
      """ruby
      RSpec.describe "Composed expectations with `.or`" do
        let(:dbl) { double("Some Collaborator") }

        before do
          allow(dbl).to receive_messages(foo: nil, bar: nil)
          expect(dbl).to receive(:foo)
                     .or receive(:bar)
        end

        it "passes if both messages received" do
          dbl.foo
          dbl.bar
        end

        it "passes if only first message received" do
          dbl.foo
        end

        it "passes if only second message received" do
          dbl.bar
        end
      end
      """
    When I run `rspec or_expectations_spec.rb`
    Then the examples should all pass
