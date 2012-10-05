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
        instance_methods_of(mod_1).should_not include(:stub, :should_receive)
        instance_methods_of(mod_2).should_not include(:stub, :should_receive)

        config.add_stub_and_should_receive_to(mod_1, mod_2)

        instance_methods_of(mod_1).should include(:stub, :should_receive)
        instance_methods_of(mod_2).should include(:stub, :should_receive)
      end
    end
  end
end

