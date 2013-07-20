Feature: create an instance double

  Scenario: instance double in isolation
    Given a file named "example_spec.rb" with:
      """ruby
      describe "instance_double in isolation" do
        it "blah" do
          o = instance_double('MyClass', foo: :return_value)
          expect(o.foo).to eq(:return_value)
        end
      end
      """
    When I run `rspec example_spec.rb`
    Then the examples should all pass

  Scenario: instance double with dependencies loaded
    Given a file named "example_spec.rb" with:
      """ruby
      class MyClass
      end

      describe "instance_double" do
        it "blah" do
          instance_double('MyClass', foo: :return_value)
        end
      end
      """
    When I run `rspec example_spec.rb`
    Then the output should contain "1 example, 1 failure"
