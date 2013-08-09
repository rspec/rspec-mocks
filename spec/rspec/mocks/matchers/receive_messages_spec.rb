require 'spec_helper'

module RSpec
  module Mocks
    describe "allow(...).to receive_messages(:a => 1, :b => 2)" do
      let(:obj) { double "Object" }

      it "allows the object to respond to multiple messages" do
        allow(obj).to receive_messages(:a => 1, :b => 2)
        expect(obj.a).to eq 1
        expect(obj.b).to eq 2
      end

      it "allows single expectations" do
        allow(obj).to receive_messages(:a => 1)
        expect(obj.a).to eq 1
      end

      it "complains if a block is given" do
        expect do
          allow(obj).to receive_messages(:a => 1) { "implementation" }
        end.to raise_error "Implementation blocks arn't supported with `receive_messages`"
      end
    end

    describe "expect(...).to receive_messages(:a => 1, :b => 2)" do
      let(:reporter) { RSpec::Core::Reporter.new }

      it "sets up multiple expectations" do
        expect(reporter).to receive(:example_passed).with("will pass")
        expect(reporter).to receive(:example_failed).with("will fail")

        example_group = ::RSpec::Core::ExampleGroup.describe do
          before do
            obj = double "Object"
            expect(obj).to receive_messages(:a => 1, :b => 2)
          end

          it "will pass" do
            obj.a && obj.b
          end

          it "will fail" do
            obj.a
          end
        end
        example_group.run reporter
      end

      it "allows single expectations" do
        expect(reporter).to receive(:example_passed).with("will pass")
        expect(reporter).to receive(:example_failed).with("will fail")

        example_group = ::RSpec::Core::ExampleGroup.describe do
          before do
            obj = double "Object"
            expect(obj).to receive_messages(:a => 1)
          end

          it "will pass" do
            obj.a
          end

          it "will fail" do
          end
        end
        example_group.run reporter
      end

      it "complains if a block is given" do
        expect do
          expect(double).to receive_messages(:a => 1) { "implementation" }
        end.to raise_error "Implementation blocks arn't supported with `receive_messages`"
      end
    end
  end
end
