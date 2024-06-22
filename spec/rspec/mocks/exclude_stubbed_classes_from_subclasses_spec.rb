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
          it 'extends Class with methods' do
            expect {
              described_class.enable!
            }.to change { Class.respond_to?(:subclasses_with_rspec_mocks) }.from(false).to(true)
          end

          it 'does not extends Class when it has been enabled' do
            allow(Class).to receive(:class_eval).and_call_original

            described_class.enable!
            described_class.enable!

            expect(Class).to have_received(:class_eval).once
          end

          it 'excludes stubbed classes from subclasses' do
            described_class.enable!

            orignal_subclasses = TestClass.subclasses

            subclass = Class.new(TestClass)
            described_class.exclude_subclass(subclass)

            expect(TestClass.subclasses).to an_array_matching(orignal_subclasses)
          end
        end

        describe '.disable!' do
          it 'does nothing when it has not been enabled' do
            expect { described_class.disable! }.not_to raise_error
          end

          it 'removes methods from class when it has been enabled' do
            described_class.enable!
            expect {
              described_class.disable!
            }.to change { Class.respond_to?(:subclasses_with_rspec_mocks) }.from(true).to(false)
          end

          it 'does not exclude stubbed classes from subclasses' do
            described_class.enable!
            described_class.disable!

            orignal_subclasses = TestClass.subclasses

            subclass = Class.new(TestClass)
            described_class.exclude_subclass(subclass)

            expect(TestClass.subclasses).to an_array_matching(orignal_subclasses + [subclass])
          end
        end

        describe '.excluded_subclasses' do
          it 'returns excluded subclasses' do
            subclass = Class.new
            described_class.exclude_subclass(subclass)

            expect(described_class.excluded_subclasses).to an_array_matching([subclass])
          end

          it 'does not return excluded subclasses that have been garbage collected' do
            subclass = Class.new
            described_class.exclude_subclass(subclass)

            subclass = nil

            GC.start

            expect(described_class.excluded_subclasses).to eq([])
          end

          it 'does not return excluded subclasses that raises a ::WeakRef::RefError' do
            require 'weakref'
            subclass = double(:weakref_alive? => true)
            described_class.instance_variable_set(:@excluded_subclasses, [subclass])

            allow(subclass).to receive(:__getobj__).and_raise(::WeakRef::RefError)

            expect(described_class.excluded_subclasses).to eq([])
          end
        end
      end
    end
  end
end
