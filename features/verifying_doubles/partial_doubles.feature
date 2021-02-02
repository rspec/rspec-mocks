Feature: Partial doubles

  The same argument and method existence checks that are performed for [`object_double`](./using-an-object-double) are also performed on
  [partial doubles](../basics/partial-test-doubles). You should only turn off `verify_partial_doubles` (by setting it to false)
  if you have a really good reason to.

  Scenario: doubling an existing object
    Given a file named "spec/user_spec.rb" with:
      """ruby
      class User
        def save; false; end
      end

      def save_user(user)
        "saved!" if user.save
      end

      RSpec.describe '#save_user' do
        it 'renders message on success' do
          user = User.new
          expect(user).to receive(:saave).and_return(true) # Typo in name
          expect(save_user(user)).to eq("saved!")
        end
      end
      """
    When I run `rspec spec/user_spec.rb`
    Then the output should contain "1 example, 1 failure"

  Scenario: Stubbing a non-existent or a dynamic method
    Given a file named "spec/user_spec.rb" with:
      """ruby
      RSpec.configure do |config|
        config.mock_with :rspec do |mocks|
          mocks.verify_partial_doubles = false
        end
      end

      class Solution
        def self.best
          find_by_complexity
        end
      end

      RSpec.describe '#find_by_complexity' do
        it 'finds a simple solution' do
          expect(Solution).to receive(:find_by_complexity).and_return("simple") # Method isn't defined
          expect(Solution.best).to eq("simple")
        end
      end
      """
    When I run `rspec spec/user_spec.rb`
    Then the output should contain "1 example, 0 failures"
