Feature: expect a message on any instance of a class

  Use `expect_any_instance_of(Class).to receive` to set an expectation that one
  (and only one) instance of a class receives a message before the example is
  completed.

  The example will fail if no instance receives the specified message.

  Scenario: expect a message on any instance of a class
    Given a file named "example_spec.rb" with:
    """ruby
      describe "expect_any_instance_of" do
        before do
          expect_any_instance_of(Object).to receive(:foo).and_return(:return_value)
        end

        it "verifies that one instance of the class receives the message" do
          o = Object.new
          expect(o.foo).to eq(:return_value)
        end

        it "fails unless an instance receives that message" do
        end
      end
      """
    When I run `rspec example_spec.rb`
    Then the output should contain "2 examples, 1 failure"
    And the output should contain "1) expect_any_instance_of fails unless an instance receives that message"

  Scenario: expect a message on any instance of a class (should syntax)
    Given a file named "example_spec.rb" with:
      """ruby
      describe "any_instance.should_receive" do
        it "verifies that one instance of the class receives the message" do
          Object.any_instance.should_receive(:foo).and_return(:return_value)

          o = Object.new
          expect(o.foo).to eq(:return_value)
        end
      end
      """
    When I run `rspec example_spec.rb`
    Then the examples should all pass
