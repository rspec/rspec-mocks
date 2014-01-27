require 'spec_helper'

module RSpec
  module Mocks
    describe TestDouble do
      before(:all) do
        Module.class_exec do
          private
          def use; end
        end
      end

      after(:all) do
        Module.class_exec do
          undef use
        end
      end

      it 'can be extended onto a module to make it a pure test double that can mock private methods' do
        double = Module.new
        double.stub(:use)
        expect { double.use }.to raise_error(/private method `use' called/)

        double = Module.new { TestDouble.extend_onto(self) }
        double.should_receive(:use).and_return(:ok)
        expect(double.use).to be(:ok)
      end

      it 'sets the test double name when a name is passed' do
        double = Module.new { TestDouble.extend_onto(self, "MyDouble") }
        expect { double.foo }.to raise_error(/Double "MyDouble" received/)
      end

      [[:should, :expect], [:expect], [:should]].each do |syntax|
        context "with syntax #{syntax.inspect}" do
          include_context "with syntax", syntax
          it 'stubs the methods passed in the stubs hash' do
            double = Module.new do
              TestDouble.extend_onto(self, "MyDouble", :a => 5, :b => 10)
            end

            expect(double.a).to eq(5)
            expect(double.b).to eq(10)
          end
        end
      end
    end
  end
end
