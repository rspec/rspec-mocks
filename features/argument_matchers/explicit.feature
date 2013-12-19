Feature: explicit arguments

  Allows you to explicitly specify the argument values

  Scenario: explicit arguments
    Given a file named "stub_explicit_args_spec.rb" with:
      """ruby
      describe "stubbed explicit arguments" do
        it "works on stubs" do
          object = Object.new
          allow(object).to receive(:foo).with(:this) do |arg|
            "got this"
          end
          allow(object).to receive(:foo).with(:that) do |arg|
            "got that"
          end

          expect(object.foo(:this)).to eq("got this")
          expect(object.foo(:that)).to eq("got that")
        end

        it "works on doubles and expectations" do
          object = double('foo')
          expect(object).to receive(:bar).with(:foo)

          object.bar(:foo)
        end
      end
      """
    When I run `rspec stub_explicit_args_spec.rb`
    Then the output should contain "2 examples, 0 failures"

  Scenario: explicit arguments with multiple arities
    Given a file named "stub_multiple_explicit_args_spec.rb" with:
      """ruby
      describe "stubbed multiple explicit arguments" do
        it "works on stubs" do
          object = Object.new
          allow(object).to receive(:foo).with(:this) do |arg|
            "got this"
          end
          allow(object).to receive(:foo).with(:this, :that) do |arg1, arg2|
            "got this and that"
          end

          expect(object.foo(:this)).to eq("got this")
          expect(object.foo(:this, :that)).to eq("got this and that")
        end

        it "works on mocks" do
          object = double('foo')
          expect(object).to receive(:foo).with(:this, :that)

          object.foo(:this, :that)
        end
      end
      """
    When I run `rspec stub_multiple_explicit_args_spec.rb`
    Then the output should contain "2 examples, 0 failures"
