require 'spec_helper'

class LoadedClass
  def defined_instance_method; end
  def self.defined_class_method; end
end

module RSpec
  module Mocks
    describe 'verifying doubles' do
      def prevents(&block)
        expect(&block).to \
          raise_error(RSpec::Expectations::ExpectationNotMetError)
      end

      describe 'instance double' do
        describe 'when doubled class is not loaded' do
          it 'allows any instance method to be stubbed' do
            o = instance_double('NonloadedClass')
            o.stub(:undefined_instance_method).with(:arg).and_return(true)
            expect(o.undefined_instance_method(:arg)).to eq(true)
          end
        end

        describe 'when doubled class is loaded' do
          it 'only allows instance methods that exist to be stubbed' do
            o = instance_double('LoadedClass', defined_instance_method: true)
            expect(o.defined_instance_method).to eq(true)

            prevents { o.stub(:undefined_instance_method) }
            prevents { o.stub(:defined_class_method) }
          end

          it 'only allows instance methods that exist to be expected' do
            o = instance_double('LoadedClass')
            expect(o).to receive(:defined_instance_method)
            o.defined_instance_method

            prevents { expect(o).to receive(:undefined_instance_method) }
            prevents { expect(o).to receive(:defined_class_method) }
          end

          it 'checks the arity of stubbed methods' do
            o = instance_double('LoadedClass')
            prevents {
              expect(o).to receive(:defined_instance_method).with(:a)
            }
          end
        end
      end

      describe 'class double' do
        describe 'when doubled class is not loaded' do
          it 'allows any method to be stubbed' do
            o = class_double('NonloadedClass')
            o.stub(:undefined_instance_method).with(:arg).and_return(true)
            expect(o.undefined_instance_method(:arg)).to eq(true)
          end
        end

        describe 'when doubled class is loaded' do
          it 'only allows class methods that exist to be stubbed' do
            o = class_double('LoadedClass', defined_class_method: true)
            expect(o.defined_class_method).to eq(true)

            prevents { o.stub(:undefined_instance_method) }
            prevents { o.stub(:defined_instance_method) }
          end

          it 'only allows class methods that exist to be expected' do
            o = class_double('LoadedClass')
            expect(o).to receive(:defined_class_method)
            o.defined_class_method

            prevents { expect(o).to receive(:undefined_instance_method) }
            prevents { expect(o).to receive(:defined_instance_method) }
          end
        end
      end
    end
  end
end
