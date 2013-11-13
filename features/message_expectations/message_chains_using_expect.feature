Feature: Message chains in the expect syntax

  You can use `receive_message_chain` to stub nested calls
  on both partial and pure mock objects.

  Scenario: allow a chained message
    Given a file named "spec/chained_messages.rb" with:
      """ruby
      describe "a chained message expectation" do
        it "passes if the expected number of calls happen" do
          d = double
          allow(d).to receive_message_chain(:to_a, :length)

          d.to_a.length
        end
      end
      """
    When I run `rspec spec/chained_messages.rb`
    Then the output should contain "1 example, 0 failures"

  Scenario: allow a chained message with a return value
    Given a file named "spec/chained_messages.rb" with:
      """ruby
      describe "a chained message expectation" do
        it "passes if the expected number of calls happen" do
          d = double
          allow(d).to receive_message_chain(:to_a, :length).and_return(3)

          expect(d.to_a.length).to eq(3)
        end
      end
      """
    When I run `rspec spec/chained_messages.rb`
    Then the output should contain "1 example, 0 failures"

  Scenario: expect a chained message with a return value
    Given a file named "spec/chained_messages.rb" with:
      """ruby
      describe "a chained message expectation" do
        it "passes if the expected number of calls happen" do
          d = double
          expect(d).to receive_message_chain(:to_a, :length).and_return(3)

          expect(d.to_a.length).to eq(3)
        end
      end
      """
    When I run `rspec spec/chained_messages.rb`
    Then the output should contain "1 example, 0 failures"
