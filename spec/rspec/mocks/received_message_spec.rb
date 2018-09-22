
require "spec_helper"

RSpec.describe RSpec::Mocks::ReceivedMessage do
  let(:fake) { double }
  let(:proxy) { fake.send :__mock_proxy }

  it "will find nothing when no methods are stubbed stubbed" do
    received_message_foo = proxy.build_received_message(:foo)
    expect(received_message_foo.find_matching_stub).to eq(nil)
  end

  context "when a method has been stubbed" do
    let (:matching_received_message) { proxy.build_received_message(:foo, 1, 2) }
    let (:partial_match_recieved_message) { proxy.build_received_message(:foo) }

    before (:each) { allow(fake).to receive(:foo).with(1, 2) }

    it "can find a stub matching a message name and its arguments" do
      message_expectation = matching_received_message.find_matching_stub
      expect(message_expectation.matches?(:foo, 1, 2)).to eq(true)
    end

    it "will not find a stub expecting arguments matching a message with no arguments" do
      expect(partial_match_recieved_message.find_matching_stub).to eq(nil)
    end

    it "will not find a stub matching a message when its arguments don't match" do
      received_message_foo = proxy.build_received_message(:foo, 1)
      expect(received_message_foo.find_matching_stub).to eq(nil)
    end

    it "can find a stub when a received message matches the name but not its arguments" do
      message_expectation = partial_match_recieved_message.find_almost_matching_stub
      expect(message_expectation.matches?(:foo, 1, 2)).to eq(true)
    end
  end

  context "when a method has been mocked" do
    let (:matching_received_message) { proxy.build_received_message(:foo, 1, 2) }
    let (:partial_match_recieved_message) { proxy.build_received_message(:foo) }

    before (:each) do
      expect(fake).to receive(:foo).with(1, 2)
      fake.foo(1, 2)
    end

    it "can find a stub matching a message name and its arguments" do
      message_expectation = matching_received_message.find_matching_expectation
      expect(message_expectation.matches?(:foo, 1, 2)).to eq(true)
    end

    it "will not find a stub expecting arguments matching a message with no arguments" do
      expect(partial_match_recieved_message.find_matching_expectation).to eq(nil)
    end

    it "will not find a stub matching a message when its arguments don't match" do
      received_message_foo = proxy.build_received_message(:foo, 1)
      expect(received_message_foo.find_matching_expectation).to eq(nil)
    end

    it "can find a stub when a received message matches the name but not its arguments" do
      message_expectation = partial_match_recieved_message.find_almost_matching_expectation
      expect(message_expectation.matches?(:foo, 1, 2)).to eq(true)
    end
  end
end
