Feature: Verifying doubles

  Verifying doubles are a stricter alternative to normal doubles that provide
  guarantees about what is being verified.  When using verifying doubles, RSpec
  will check that the methods being stubbed are actually present on the
  underlying object if it is available. Prefer using veryifing doubles over
  normal doubles.

  No checking will happen if the constant name is not defined, but when run
  with the constant present (either as a full spec run or by explicitly
  preloading collaborators) a failure will be triggered if an invalid method is
  being stubbed.

  This dual approach allows you to move very quickly and test components in
  isolation, while giving you confidence that your doubles are not a complete
  fiction. Testing in isolation is optional but recommend for classes that do
  not depend on third-party components.

  Background:
    Given a file named "app/models/user.rb" with:
      """ruby
      class User < Struct.new(:notifier)
        def suspend!
          notifier.notify("suspended as")
        end
      end
      """

    Given a file named "app/models/console_notifier.rb" with:
      """ruby
      class ConsoleNotifier
        # notify is not defined yet.
      end
      """

    Given a file named "spec/unit_helper.rb" with:
      """ruby
      $LOAD_PATH.unshift("app/models")
      """

    Given a file named "spec/spec_helper.rb" with:
      """ruby
      require 'unit_helper'

      require 'user'
      require 'console_notifier'

      RSpec.configure do |config|
        config.mock_with :rspec do |mocks|

          # This option should be set when all dependencies are being loaded
          # before a spec run, as is the case in a typical spec helper. It will
          # cause any verifying double instantiation for a class that does not
          # exist to raise, protecting against incorrectly spelt names.
          mocks.verify_doubled_constant_names = true

        end
      end
      """

    Given a file named "spec/unit/user_spec.rb" with:
      """ruby
      require 'unit_helper'

      require 'user'

      describe User, '#suspend!' do
        it 'notifies the console' do
          notifier = instance_double("ConsoleNotifier")

          expect(notifier).to receive(:notify).with("suspended as")

          user = User.new(notifier)
          user.suspend!
        end
      end
      """

  Scenario: spec passes in isolation
    When I run `rspec spec/unit/user_spec.rb`
    Then the examples should all pass

  Scenario: spec fails with dependencies loaded
    When I run `rspec -r./spec/spec_helper spec/unit/user_spec.rb`
    Then the output should contain "1 example, 1 failure"
