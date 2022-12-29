Feature: Returning a value

  Use `and_return` to specify a return value. Pass `and_return` multiple values to specify
  different return values for consecutive calls. The final value will continue to be returned if
  the message is received additional times.

  Scenario: Nil is returned by default
    Given a file named "returns_nil_spec.rb" with:
      """ruby
      RSpec.describe "The default response" do
        it "returns nil when no response has been configured" do
          dbl = double
          allow(dbl).to receive(:foo)
          expect(dbl.foo).to be_nil
        end
      end
      """
     When I run `rspec returns_nil_spec.rb`
     Then the examples should all pass

  Scenario: Specify a return value
    Given a file named "and_return_spec.rb" with:
      """ruby
      RSpec.describe "Specifying a return value" do
        it "returns the specified return value" do
          dbl = double
          allow(dbl).to receive(:foo).and_return(14)
          expect(dbl.foo).to eq(14)
        end
      end
      """
     When I run `rspec and_return_spec.rb`
     Then the examples should all pass

  Scenario: Specify different return values for multiple calls
    Given a file named "multiple_calls_spec.rb" with:
      """ruby
      RSpec.describe "When the method is called multiple times" do
        it "returns the specified values in order, then keeps returning the last value" do
          dbl = double
          allow(dbl).to receive(:foo).and_return(1, 2, 3)

          expect(dbl.foo).to eq(1)
          expect(dbl.foo).to eq(2)
          expect(dbl.foo).to eq(3)
          expect(dbl.foo).to eq(3) # begins to repeat last value
          expect(dbl.foo).to eq(3)
        end
      end
      """
     When I run `rspec multiple_calls_spec.rb`
     Then the examples should all pass

  Scenario: Specify different return values for multiple calls in combination with allow_any_instance_of

    Using the multiple calls feature with `allow_any_instance_of` can result in confusing behavior.  With
    `allow_any_instance_of`, the multiple calls are configured on the class, but tracked on the instance.  Therefore,
    each individual instance will return the configured return values in the order specified, and then begin to repeat
    the last value, as demonstrated in this code:

    Given a file named "multiple_calls_spec_with_allow_any_instance_of.rb" with:
      """ruby
      class SomeClass
      end

      RSpec.describe "When the method is called multiple times on different instances with allow_any_instance_of" do
        it "demonstrates the mocked behavior on each instance individually" do
          allow_any_instance_of(SomeClass).to receive(:foo).and_return(1, 2, 3)

          first = SomeClass.new
          second = SomeClass.new
          third = SomeClass.new

          expect(first.foo).to eq(1)
          expect(second.foo).to eq(1)

          expect(first.foo).to eq(2)
          expect(second.foo).to eq(2)

          expect(first.foo).to eq(3)
          expect(first.foo).to eq(3) # begins to repeat last value
          expect(second.foo).to eq(3)
          expect(second.foo).to eq(3) # begins to repeat last value

          expect(third.foo).to eq(1)
          expect(third.foo).to eq(2)
          expect(third.foo).to eq(3)
          expect(third.foo).to eq(3) # begins to repeat last value
        end
      end
      """
    When I run `rspec multiple_calls_spec_with_allow_any_instance_of.rb`
    Then the examples should all pass
