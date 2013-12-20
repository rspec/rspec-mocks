Feature: General matchers

  The `anything`,  `any_args`,  and `no_args` matchers can be used to require the method
  to have arguments (or not) without constraining the details of the argument, such as its
  type,  pattern or value. The `anything` matcher only reflects a single argument, while
  the `any_args` matcher matches any arity.

  Scenario: anything argument matcher
    Given a file named "stub_anything_args_spec.rb" with:
      """ruby
      describe "stubbed anything() args spec" do
        it "works" do
          object = Object.new
          allow(object).to receive(:foo).with(anything) do
            "anything"
          end

          expect(object.foo(1)).to eq("anything")
          expect(object.foo(:that)).to eq("anything")
        end
      end
      """
    When I run `rspec stub_anything_args_spec.rb`
    Then the output should contain "1 example, 0 failures"

  Scenario: any_args argument matcher
    Given a file named "stub_any_args_spec.rb" with:
      """ruby
      describe "stubbed any_args() args spec" do
        it "works" do
          object = Object.new
          allow(object).to receive(:foo).with(any_args) do
            "anything"
          end

          expect(object.foo(1)).to eq("anything")
          expect(object.foo(:that)).to eq("anything")
          expect(object.foo).to eq("anything")
        end
      end
      """
    When I run `rspec stub_any_args_spec.rb`
    Then the output should contain "1 example, 0 failures"

  Scenario: no_args argument matcher
    Given a file named "stub_no_args_spec.rb" with:
      """ruby
      describe "stubbed no_args() args spec" do
        it "works for no args" do
          object = Object.new
          allow(object).to receive(:foo).with(no_args) do
            "nothing"
          end
          allow(object).to receive(:foo).with(anything) do
            "something"
          end

          expect(object.foo(:that)).to eq("something")
          expect(object.foo).to eq("nothing")
        end
      end
      """
    When I run `rspec stub_no_args_spec.rb`
    Then the output should contain "1 example, 0 failures"

  Scenario: no_args argument matcher for expectations
    Given a file named "stub_no_args_expectations_spec.rb" with:
      """ruby
      describe "stubbed no_args() args spec for expectations" do
        it "works for no args" do
          object = Object.new
          expect(object).to receive(:foo).with(no_args)

          object.foo
        end
        it "fails for args" do
          object = Object.new
          expect(object).to receive(:foo).with(no_args)

          object.foo(:bar)
        end
      end
      """
    When I run `rspec stub_no_args_expectations_spec.rb`
    Then the output should contain "2 examples, 1 failure"
