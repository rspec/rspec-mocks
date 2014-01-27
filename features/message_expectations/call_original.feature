Feature: Calling the original method

  You can use `and_call_original` on the fluent interface
  to "pass through" the received message to the original method.

  Scenario: expect a message
    Given a file named "call_original_spec.rb" with:
      """ruby
      class Addition
        def self.two_plus_two
          4
        end
      end

      describe "and_call_original" do
        it "delegates the message to the original implementation" do
          expect(Addition).to receive(:two_plus_two).and_call_original
          expect(Addition.two_plus_two).to eq(4)
        end
      end
      """
    When I run `rspec call_original_spec.rb`
    Then the examples should all pass
