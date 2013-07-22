### Introduction

When using verifying doubles, RSpec will check that the methods being stubbed
are actually present on the underlying object if it is available.

No checking will happen when running the spec in isolation, but when run in the
context of the full application (either as a full spec run or by explicitly
preloading collaborators on the command line) a failure will be triggered if an
invalid method is being stubbed.

For example, specify the class being doubled in your specs:

    class User < Struct.new(:notifier)
      def suspend!
        notifier.notify("suspended as")
      end
    end

    describe User, '#suspend!' do
      it 'sends a notification' do
        # Only this one line differs from how you write specs normally
        notifier = instance_double("EmailNotifier")

        expect(notifier).to receive(:notify).with("suspended as")

        user = User.new(notifier)
        user.suspend!
      end
    end

Then run your specs:

    rspec spec/user_spec.rb

This will pass, since `EmailNotifier` has not been loaded so there is no way
for RSpec to verify whether `notify` is a real method.

Running again with `EmailNotifier` loaded:

    rspec -Ilib -remail_notifier.rb spec/user_spec.rb

This time it will fail since `EmailNotifier` has been loaded and RSpec can see
what methods have actually been defined on it.

This dual approach allows you to move very quickly and test components in
isolation, but gives you confidence that your doubles are not a complete
fiction.
