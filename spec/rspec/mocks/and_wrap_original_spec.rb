RSpec.describe "and_wrap_original" do
  context "on a partial double" do
    let(:klass) do
      Class.new do
        def results
          (1..100).to_a
        end
      end
    end

    let(:instance) { klass.new }

    shared_examples "using and_wrap_original" do
      context 'with a class inheriting a method using argument forwarding' do
        class ApplicationService
          class << self
            private_class_method :new

            def call_now(...)
              new(...).call
            end
          end
        end

        class MyService < ApplicationService
          def initialize(my_object:)
            @my_object = my_object
          end

          def call
          end

          private

          attr_reader :my_object
        end

        current_time = nil

        before do
          allow(MyService).to receive(:call_now).and_wrap_original do |blk, *args|
            blk.call(*args)
            current_time = Time.now
          end
        end

        it "allows us to modify the results of the original method" do
          MyService.call_now(my_object: nil)

          expect(current_time).not_to be_nil
        end
      end

      it "allows us to modify the results of the original method" do
        expect {
          allow_it.to receive(:results).and_wrap_original do |m|
            m.call.first(10)
          end
        }.to change { instance.results.size }.from(100).to(10)
      end

      it "raises a name error if the method does not exist" do
        expect {
          allow_it.to receive(:no_results).and_wrap_original { |m| m.call }
          instance.no_results
        }.to raise_error NameError
      end

      it "passes along the original method" do
        passed_method = nil
        original_method = instance.method(:results)
        allow_it.to receive(:results).and_wrap_original { |m| passed_method = m }
        instance.results

        expect(passed_method.call).to eq(original_method.call)
      end

      it "passes along the message arguments" do
        values = nil
        allow_it.to receive(:results).and_wrap_original { |_, *args| values  = args }
        instance.results(1, 2, 3)
        expect(values).to eq [1, 2, 3]
      end

      it "passes along any supplied block" do
        value = nil
        allow_it.to receive(:results).and_wrap_original { |&b| value = b }
        instance.results(&(block = proc {}))
        expect(value).to eq block
      end

      it "ignores previous stubs" do
        allow_it.to receive(:results) { "results" }
        allow_it.to receive(:results).and_wrap_original { |m| m.call }
        expect(instance.results).to_not eq "results"
      end

      it "can be constrained by specific arguments" do
        allow_it.to receive(:results) { :all }
        allow_it.to receive(:results).with(5).and_wrap_original { |m, n| m.call.first(n) }
        expect(instance.results 5).to eq [1, 2, 3, 4, 5]
        expect(instance.results).to eq :all
      end

      if RSpec::Support::RubyFeatures.kw_args_supported?
        binding.eval(<<-CODE, __FILE__, __LINE__)
        it "works for methods that accept keyword arguments, using a keyword argument block" do
          def instance.foo(bar: nil); bar; end
          allow(instance).to receive(:foo).and_wrap_original { |m, **kwargs| m.call(**kwargs) }
          expect(instance.foo(bar: "baz")).to eq("baz")
        end
        CODE
      end
    end

    describe "allow(...).to receive(...).and_wrap_original" do
      it_behaves_like "using and_wrap_original" do
        let(:allow_it) { allow(instance) }
      end
    end

    describe "allow_any_instance_of(...).to receive(...).and_wrap_original" do
      it_behaves_like "using and_wrap_original" do
        let(:allow_it) { allow_any_instance_of(klass) }
      end
    end
  end

  context "on a pure test double" do
    let(:instance) { double :my_method => :my_value }

    it 'raises an error' do
      mock_expectation = allow(instance).to receive(:my_method)

      expect {
        mock_expectation.and_wrap_original
      }.to raise_error(/pure test double.*and_wrap_original.*partial double/i)
    end

    it 'raises an error even if the double object responds to the message' do
      mock_expectation = allow(instance).to receive(:inspect)

      expect {
        mock_expectation.and_wrap_original
      }.to raise_error(/pure test double.*and_wrap_original.*partial double/i)
    end
  end
end
