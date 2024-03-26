if RUBY_VERSION >= '3.1'
  class TestClass
  end

  module RSpec
    module Mocks
      RSpec.describe ExcludeStubbedClassesFromSubclasses do
        after do
          described_class.disable!
        end

        describe '.enable!' do
          it 'does not extends Class when it has been enabled' do
            allow(described_class).to receive(:extend).once

            described_class.enable!
            described_class.enable!

            expect(described_class).to have_received(:extend).once
          end

          it 'extends RSpec::Mocks with methods' do
            described_class.enable!
            expect(described_class).to respond_to(:excluded_subclasses)
          end

          it 'extends Class with methods' do
            expect {
              described_class.enable!
            }.to change { Class.respond_to?(:subclasses_with_rspec_mocks) }.from(false).to(true)
          end

          it 'excludes stubbed classes from subclasses' do
            ::RSpec::Mocks.space.reset_all
            RSpec::Mocks.configuration.exclude_stubbed_classes_from_subclasses = true

            orignal_subclasses = TestClass.subclasses

            subclass = Class.new(TestClass)
            stub_const('TestSubClass', subclass)

            expect {
              ::RSpec::Mocks.space.reset_all
            }.to change { TestClass.subclasses }.from(orignal_subclasses + [subclass]).to(orignal_subclasses)
          end
        end

        describe '.disable!' do
          it 'does nothing when it has not been enabled' do
            expect { described_class.disable! }.not_to raise_error
          end

          it 'removes methods when it has been enabled' do
            described_class.enable!
            expect {
              described_class.disable!
            }.to change { Class.respond_to?(:subclasses_with_rspec_mocks) }.from(true).to(false)
          end

          it 'does not exclude stubbed classes from subclasses' do
            subclass = Class.new(TestClass)

            stub_const('TestSubClass', subclass)

            ::RSpec::Mocks.space.reset_all
            expect(TestClass.subclasses).to include(subclass)
          end
        end
      end
    end
  end
end
