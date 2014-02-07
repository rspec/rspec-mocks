require 'spec_helper'

module RSpec
  module Mocks
    describe 'and_return' do
      let(:obj) { double('obj') }

      context 'when a block is passed' do
        it 'raises ArgumentError' do
          expect {
            obj.stub(:foo).and_return('bar') { 'baz' }
          }.to raise_error(ArgumentError, /implementation block/i)
        end
      end

      context 'when no argument is passed' do
        it 'raises ArgumentError' do
          expect { obj.stub(:foo).and_return }.to raise_error(ArgumentError)
        end
      end
    end
  end
end
