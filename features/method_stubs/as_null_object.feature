Feature: as_null_object

  Use the `as_null_object` method to ignore any messages that aren't explicitly
  set as stubs or message expectations.

  EXCEPTION: `to_ary` will raise a NoMethodError unless explicitly stubbed in
  order to support `flatten` on an Array containing a double.

  Scenario: double acting as_null_object
    Given a file named "as_null_object_spec.rb" with:
      """ruby
      describe "a double with as_null_object called" do
        let(:null_object) { double('null object').as_null_object }

        it "responds to any method that is not defined" do
          expect(null_object).to respond_to(:an_undefined_method)
        end

        it "allows explicit stubs using expect syntax" do
          allow(null_object).to receive(:foo) { "bar" }
          expect(null_object.foo).to eq("bar")
        end

        it "allows explicit stubs using should syntax" do
          null_object.stub(:foo) { "bar" }
          expect(null_object.foo).to eq("bar")
        end

        it "allows explicit expectations" do
          expect(null_object).to receive(:something)
          null_object.something
        end

        it "supports Array#flatten" do
          expect([null_object].flatten).to eq([null_object])
        end
      end
      """
    When I run `rspec as_null_object_spec.rb`
    Then the examples should all pass
