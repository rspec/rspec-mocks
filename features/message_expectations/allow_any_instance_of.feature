Feature: allow a message on any instance of a class

  Use `allow_any_instance_of(Class).to receive` when an instance of a class is
  allowed to respond to a particular message. This will not set an expectation
  on any instance so the spec will not fail if no instance receives the message.

  Scenario: allowing a message on any instance of a class
    Given a file named "example_spec.rb" with:
      """ruby
      describe "any_instance.should_receive" do
        before do
          allow_any_instance_of(Object).to receive(:foo).and_return(:return_value)
        end

        it "allows any instance of the class to receive the message" do
          o = Object.new
          expect(o.foo).to eq(:return_value)
        end

        it "passes even if no instances receive that message" do
          o = Object.new
        end
      end
      """
    When I run `rspec example_spec.rb`
    Then the examples should all pass
