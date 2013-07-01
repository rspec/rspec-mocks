require 'spec_helper'

describe Marshal, 'extensions' do
  # An object that raises when code attempts to dup it.
  #
  # Because we manipulate the internals of RSpec::Mocks.space below, we need
  # an object that simply blows up when #dup is called without using any
  # partial mocking or stubbing from rspec-mocks itself.
  class UndupableObject
    def dup
      raise NotImplementedError
    end
  end

  describe '#dump' do
    context 'when rspec-mocks has not been fully initialized' do
      def without_space
        stashed_space, RSpec::Mocks.space = RSpec::Mocks.space, nil
        yield
      ensure
        RSpec::Mocks.space = stashed_space
      end

      it 'does not duplicate the object before serialization' do
        obj = UndupableObject.new
        without_space do
          expect { Marshal.dump(obj) }.not_to raise_error
        end
      end
    end

    context 'when rspec-mocks has been fully initialized' do
      it 'duplicates objects with stubbed or mocked implementations before serialization' do
        obj = double(:foo => "bar")
        expect { Marshal.dump(obj) }.not_to raise_error
      end

      it 'does not duplicate other objects before serialization' do
        obj = UndupableObject.new
        expect { Marshal.dump(obj) }.not_to raise_error
      end

      it 'does not duplicate nil before serialization' do
        expect { Marshal.dump(nil) }.not_to raise_error
      end
    end
  end
end
