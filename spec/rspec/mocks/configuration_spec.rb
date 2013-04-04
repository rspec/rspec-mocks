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

      shared_examples_for "configuring the syntax" do
        def sandboxed
          orig_syntax = RSpec::Mocks.configuration.syntax
          yield
        ensure
          configure_syntax(orig_syntax)
        end

        around(:each) { |ex| sandboxed(&ex) }
        let(:dbl) { double }
        let(:direct_methods)       { [:should_receive, :stub, :should_not_receive] }
        let(:direct_class_methods) { [:any_instance] }
        let(:wrapped_methods)      { [:receive, :allow, :expect_any_instance_of, :allow_any_instance_of] }

        it 'defaults to only enabling the :direct syntax' do
          expect(dbl).to respond_to(*direct_methods)
          expect(self).not_to respond_to(*wrapped_methods)
        end

        context 'when configured to :wrapped' do
          before { configure_syntax :wrapped }

          it 'removes the direct methods from every object' do
            expect(dbl).not_to respond_to(*direct_methods)
          end

          it 'removes `any_instance` from every class' do
            expect(Class.new).not_to respond_to(*direct_class_methods)
          end

          it 'adds the wrapped methods to the example group context' do
            expect(self).to respond_to(*wrapped_methods)
          end

          it 'reports that the syntax is :wrapped' do
            expect(configured_syntax).to eq([:wrapped])
          end

          it 'is a no-op when configured a second time' do
            expect(Syntax.default_direct_syntax_host).not_to receive(:method_undefined)
            expect(::RSpec::Mocks::ExampleMethods).not_to receive(:method_added)
            configure_syntax :wrapped
          end
        end

        context 'when configured to :direct' do
          before { configure_syntax :direct }

          it 'adds the direct methods to every object' do
            expect(dbl).to respond_to(*direct_methods)
          end

          it 'adds `any_instance` to every class' do
            expect(Class.new).to respond_to(*direct_class_methods)
          end

          it 'removes the wrapped methods from the example group context' do
            expect(self).not_to respond_to(*wrapped_methods)
          end

          it 'reports that the syntax is :direct' do
            expect(configured_syntax).to eq([:direct])
          end

          it 'is a no-op when configured a second time' do
            Syntax.default_direct_syntax_host.should_not_receive(:method_added)
            ::RSpec::Mocks::ExampleMethods.should_not_receive(:method_undefined)
            configure_syntax :direct
          end
        end

        context 'when configured to [:direct, :wrapped]' do
          before { configure_syntax [:direct, :wrapped] }

          it 'adds the direct methods to every object' do
            expect(dbl).to respond_to(*direct_methods)
          end

          it 'adds `any_instance` to every class' do
            expect(Class.new).to respond_to(*direct_class_methods)
          end

          it 'adds the wrapped methods to the example group context' do
            expect(self).to respond_to(*wrapped_methods)
          end

          it 'reports that both syntaxes are enabled' do
            expect(configured_syntax).to eq([:direct, :wrapped])
          end
        end
      end

      describe "configuring rspec-mocks directly" do
        it_behaves_like "configuring the syntax" do
          def configure_syntax(syntax)
            RSpec::Mocks.configuration.syntax = syntax
          end

          def configured_syntax
            RSpec::Mocks.configuration.syntax
          end
        end
      end

      describe "configuring using the rspec-core config API" do
        it_behaves_like "configuring the syntax" do
          def configure_syntax(syntax)
            RSpec.configure do |rspec|
              rspec.mock_with :rspec do |c|
                c.syntax = syntax
              end
            end
          end

          def configured_syntax
            RSpec.configure do |rspec|
              rspec.mock_with :rspec do |c|
                return c.syntax
              end
            end
          end
        end
      end
    end
  end
end

