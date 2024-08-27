Feature: Mixed responses

  Use `and_invoke` to invoke a callable when a message is received. Pass `and_invoke` multiple
  callables to have different behavior for consecutive calls. The final callable will continue to be
  called if the message is received additional times.

  Note: The invoked callable will be supplied the calls arguments, including any blocks (so `yield`
  et al will be supported). It is recommended to use a `lambda` or similar with the same arity
  as your method but you can use a `proc` if you do not care about arity(e.g. when raising).

  Scenario: Mixed responses
    Given a file named "raises_and_then_returns.rb" with:
      """ruby
      RSpec.describe "when the method is called multiple times" do
        it "raises and then later returns a value" do
          dbl = double
          allow(dbl).to receive(:foo).and_invoke(lambda { raise "failure" }, lambda { true })

          expect { dbl.foo }.to raise_error("failure")
          expect(dbl.foo).to eq(true)
        end
      end
      """
     When I run `rspec raises_and_then_returns.rb`
     Then the examples should all pass

  Scenario: Block arguments
    Given a file named "yields_and_raises.rb" with:
      """ruby
      RSpec.describe "when the method is called multiple times" do
        it "yields and then later raises" do
          dbl = double
          allow(dbl).to receive(:foo).and_invoke(
            proc { |&block| block.call("foo") },
            proc { raise "failure" }
          )

          dbl.foo { |yielded| expect(yielded).to eq("foo") }
          expect { dbl.foo }.to raise_error("failure")
        end
      end
      """
     When I run `rspec yields_and_raises.rb`
     Then the examples should all pass
