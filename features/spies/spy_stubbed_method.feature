Feature: Spy on a stubbed method

  You can use `have_received` to verify that a stubbed method was invoked,
  rather than setting an expectation for it to be invoked beforehand.

  Scenario: verify a stubbed method
    Given a file named "verified_spy_spec.rb" with:
      """ruby
      describe "have_received" do
        it "passes when the expectation is met" do
          invitation = double('invitation', deliver: true)
          invitation.deliver
          invitation.should have_received(:deliver)
        end
      end
      """
    When I run `rspec verified_spy_spec.rb`
    Then the examples should all pass

  Scenario: fail to verify a stubbed method
    Given a file named "failed_spy_spec.rb" with:
      """ruby
      describe "have_received" do
        it "fails when the expectation is not met" do
          invitation = double('invitation', deliver: true)
          invitation.should have_received(:deliver)
        end
      end
      """
    When I run `rspec failed_spy_spec.rb`
    Then the output should contain "expected: 1 time"
     And the output should contain "received: 0 times"
