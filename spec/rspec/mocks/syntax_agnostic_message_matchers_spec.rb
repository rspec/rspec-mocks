require "spec_helper"

module RSpec
  module Mocks

    describe ".allow_message" do
      let(:subject) { Object.new }

      it "sets up basic message allowance" do
        expect {
          ::RSpec::Mocks.allow_message(subject, :basic)
        }.to change {
          subject.respond_to?(:basic)
        }.to(true)

        expect(subject.basic).to eq(nil)
      end

      it "sets up message allowance with params and return value" do
        expect {
          ::RSpec::Mocks.allow_message(subject, :x).with(:in).and_return(:out)
        }.to change {
          subject.respond_to?(:x)
        }.to(true)

        expect(subject.x(:in)).to eq(:out)
      end

      it "accepts a callable responder for the message" do
        ::RSpec::Mocks.allow_message(subject, :message) { :value }
        expect(subject.message).to eq(:value)
      end

    end

    describe ".expect_message" do
      pending
    end

  end
end
