Feature: multiple values on an explicit receiver returns the receiver

  You can return the stubbed object when using a hash 
  in order to stubs within a single statement.
  
  Scenario: and_self
    Given a file named "multiple_values_spec.rb" with:
      """
      describe "with a hash" do
        let(:object){ Object.new }
        let(:stubbed){ object.stub(:foo => "bar") }

        it "works" do
          stubbed.should eql(object)
        end
      end
      """
    When I run `rspec multiple_values_spec.rb`
    Then the output should contain "1 example, 0 failures"
