require 'spec_helper'

module RSpec
  module Mocks
    describe 'MockExpectationError' do

      class Foo
        def self.foo
          bar
        rescue StandardError
        end
      end

      it 'is not caught by StandardError rescue blocks' do
        expect(Foo).not_to receive(:bar)
        expect {
          Foo.foo
        }.to raise_error(RSpec::Mocks::MockExpectationError)
      end
    end
  end
end
