require 'spec_helper'

module RSpec
  module Mocks
    describe Configuration do
      let(:config) { Configuration.new }
      let(:mod_1)  { Module.new }
      let(:mod_2)  { Module.new }

      def instance_methods_of(mod)
        mod_1.instance_methods.map(&:to_sym)
      end

      it 'adds stub and should_receive to the given modules' do
        expect(instance_methods_of(mod_1)).not_to include(:stub, :should_receive)
        expect(instance_methods_of(mod_2)).not_to include(:stub, :should_receive)

        config.add_stub_and_should_receive_to(mod_1, mod_2)

        expect(instance_methods_of(mod_1)).to include(:stub, :should_receive)
        expect(instance_methods_of(mod_2)).to include(:stub, :should_receive)
      end
    end
  end
end

