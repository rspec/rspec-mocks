Feature: Dynamic classes

  Verifying instance doubles do not support methods which the class reports to
  not exist since an actual instance of the class would be required to verify
  against.  This is commonly the case when `method_missing` is used.
  `ActiveRecord` does this to define methods from database columns.  If the
  object has already been loaded you may consider using an `object_double`, but
  that cannot work if you are testing in isolation.

  These types of methods are supported at class level, since `respond_to?` can
  be queried directly on the class.


  Background:
    Given a file named "lib/fake_active_record.rb" with:
      """ruby
      class FakeActiveRecord
        COLUMNS = %w[name email]

        def respond_to_missing?(method_name)
          COLUMNS.include?(method_name.to_s) || super
        end

        def method_missing(method_name, *args)
          if respond_to?(method_name)
            instance_variable_get("@#{method_name}")
          else
            super
          end
        end
      end
      """

    Given a file named "spec/user_spec.rb" with:
      """ruby
      require 'user'

      describe User do
        it 'can be doubled' do
          instance_double("User", :name => "Don")
        end
      end
      """

  Scenario: fails with method missing

    Given a file named "lib/user.rb" with:
      """ruby
      require 'fake_active_record'

      class User < FakeActiveRecord
      end
      """

    When I run `rspec spec/user_spec.rb`
    Then the output should contain "1 example, 1 failure"

  Scenario: workaround with explict definitions

    Given a file named "lib/user.rb" with:
      """ruby
      require 'fake_active_record'

      class User < FakeActiveRecord
        def name;  super end
        def email; super end
      end
      """

    When I run `rspec spec/user_spec.rb`
    Then the examples should all pass
