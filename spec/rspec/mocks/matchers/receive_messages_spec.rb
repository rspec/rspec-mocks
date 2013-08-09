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

      it "complains if a block is given" do
        expect do
          allow(obj).to receive_messages(:a => 1) { "implementation" }
        end.to raise_error "Implementation blocks arn't supported with `receive_messages`"
      end
    end

    describe "allow_any_instance_of(...).to receive_messages(:a => 1, :b => 2)" do
      let(:obj) { Object.new }

      it "allows the object to respond to multiple messages" do
        allow_any_instance_of(Object).to receive_messages(:a => 1, :b => 2)
        expect(obj.a).to eq 1
        expect(obj.b).to eq 2
      end

      it "complains if a block is given" do
        expect do
          allow_any_instance_of(Object).to receive_messages(:a => 1) { "implementation" }
        end.to raise_error "Implementation blocks arn't supported with `receive_messages`"
      end
    end

    describe "expect(...).to receive_messages(:a => 1, :b => 2)" do
      let(:obj) { double "Object" }

      it "sets up multiple expectations" do
        expect(obj).to receive_messages(:a => 1, :b => 2)
        obj.a
        expect { RSpec::Mocks.space.verify_all }.to raise_error RSpec::Mocks::MockExpectationError
      end

      it "complains if a block is given" do
        expect do
          expect(double).to receive_messages(:a => 1) { "implementation" }
        end.to raise_error "Implementation blocks arn't supported with `receive_messages`"
      end
    end

    describe "expect_any_instance_of(...).to receive_messages(:a => 1, :b => 2)" do
      let(:obj) { Object.new }

      it "sets up multiple expectations" do
        expect_any_instance_of(Object).to receive_messages(:a => 1, :b => 2)
        obj.a
        expect { RSpec::Mocks.space.verify_all }.to raise_error RSpec::Mocks::MockExpectationError
      end

      it "complains if a block is given" do
        expect do
          expect_any_instance_of(Object).to receive_messages(:a => 1) { "implementation" }
        end.to raise_error "Implementation blocks arn't supported with `receive_messages`"
      end
    end
  end
end
