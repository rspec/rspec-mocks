require 'spec_helper'

describe '#spy_on' do
  context RSpec::Mocks::TestDouble do
    let(:dbl) { double }

    it 'creates an allowance' do
      spy_on(dbl, :foo)
      expect { dbl.foo }.to_not raise_error
    end

    it 'allows expectation of message to pass' do
      spy_on(dbl, :foo)
      dbl.foo
      expect(dbl).to have_received(:foo)
    end

    it 'allows expectation of message to fail' do
      spy_on(dbl, :foo)
      expect do
        expect(dbl).to have_received(:foo)
      end.to raise_error(/received: 0/)
    end
  end

  context RSpec::Mocks::Proxy do
    let(:partial) { Widget.new('Floobit', :medium) }

    it 'can create an allowance on non-existing method' do
      spy_on(partial, :foo)
      expect { partial.foo }.to_not raise_error
    end

    it 'calls original implementation if one exists' do
      spy_on(partial, :name)
      expect(partial.name).to eq 'Floobit'
    end

    it 'allows expectation on message to pass' do
      spy_on(partial, :name)
      partial.name
      expect(partial).to have_received(:name)
    end

    it 'allows expectation on message to fail' do
      spy_on(partial, :name)
      expect do
        expect(partial).to have_received(:name)
      end.to raise_error(/received: 0/)
    end

    it 'does not observe calls to on methods not spied on' do
      spy_on(partial, :name)
      expect do
        expect(partial).to have_received(:size)
      end.to raise_error(/not been stubbed/)
    end
  end
end

class Widget
  attr_accessor :name, :size
  def initialize(name, size)
    @name = name
    @size = size
  end
end
