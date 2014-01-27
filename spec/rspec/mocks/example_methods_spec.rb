require 'spec_helper'

module RSpec
  module Mocks
    describe ExampleMethods do
      it 'does not define private helper methods since it gets included into a ' +
         'namespace where users define methods and could inadvertently overwrite ' +
         'them' do
        expect(ExampleMethods.private_instance_methods).to eq([])
      end
    end
  end
end
