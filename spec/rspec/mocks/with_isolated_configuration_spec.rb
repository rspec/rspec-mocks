require 'spec_helper'

module RSpec
  module Mocks
    describe 'the with isolated configuration shared example group' do
      @@c = describe '' do
        include_context 'with isolated configuration'
      end
      it 'resets the configuration' do
        @@c.before.first.block.call
        RSpec::Mocks.configuration.instance_eval do
          def this_method_wont_be_here
          end
        end

        @@c.after.last.block.call
        expect(RSpec::Mocks.configuration.respond_to? :this_method_wont_be_here).to be false
      end
    end
  end
end
