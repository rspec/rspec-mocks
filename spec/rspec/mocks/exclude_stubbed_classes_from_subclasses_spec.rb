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
          described_class.enable!

          expect {
            described_class.enable!
          }.not_to(change { Class.respond_to?(:subclasses_with_rspec_mocks) })
        end

        it 'extends RSpec::Mocks with methods' do
          described_class.enable!
          expect(RSpec::Mocks).to respond_to(:excluded_subclasses)
        end

        it 'extends Class with methods' do
          expect {
            described_class.enable!
          }.to change { Class.respond_to?(:subclasses_with_rspec_mocks) }.from(false).to(true)
        end

        it 'excludes stubbed classes from subclasses' do
          ::RSpec::Mocks.space.reset_all
          RSpec::Mocks.configuration.exclude_stubbed_classes_from_subclasses = true

          subclass = Class.new(TestClass)
          stub_const('TestSubClass', subclass)

          ::RSpec::Mocks.space.reset_all
          expect(TestClass.subclasses.map(&:object_id)).not_to include(subclass.object_id)
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
