Feature: stub with argument constraints

  You can further specify the behavior by constraining the type,
  format and/or number of arguments with the `#with()` method
  chained off of `#stub()`

  Scenario: an_instance_of argument matcher
    Given a file named "stub_an_instance_of_args_spec.rb" with:
      """ruby
      describe "stubbed an_instance_of() args spec" do
        it "works" do
          object = Object.new
          allow(object).to receive(:foo).with(an_instance_of(Symbol)) do
            "symbol"
          end
          allow(object).to receive(:foo).with(an_instance_of(String)) do
            "string"
          end

          expect(object.foo("bar")).to eq("string")
          expect(object.foo(:that)).to eq("symbol")
        end
      end
      """
    When I run `rspec stub_an_instance_of_args_spec.rb`
    Then the output should contain "1 example, 0 failures"
