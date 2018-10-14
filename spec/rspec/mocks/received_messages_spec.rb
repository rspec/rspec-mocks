
require "spec_helper"

RSpec.describe RSpec::Mocks::ReceivedMessages do
  let(:fake) { double }
  let(:proxy) { fake.send :__mock_proxy }
  let(:messages) { RSpec::Mocks::ReceivedMessages.new }
  let(:received_message_foo) { proxy.build_received_message(:foo) }
  let(:received_message_foo_1_2) { proxy.build_received_message(:foo, 1, 2) }
  let(:received_message_bar) { proxy.build_received_message(:bar) }

  it "is empty when created" do
    expect(messages).to be_empty
  end

  it "is not empty when a message is added to it" do
    messages << received_message_foo
    expect(messages).to_not be_empty
  end

  it "can be cleared" do
    messages << received_message_foo
    messages.clear
    expect(messages).to be_empty
  end

  context "message receipt" do
    it "knows if a message has not been received" do
      expect(messages.received?(received_message_foo)).to eq(false)
    end

    it "knows if a message has been received" do
      messages << received_message_foo
      expect(messages.received?(
          received_message_foo.name,
          *received_message_foo.args,
          &received_message_foo.block
      )).to eq(true)
    end

    it "does not match only on name" do
      messages << received_message_foo_1_2
      expect(messages.received?(
          received_message_foo.name,
          *received_message_foo.args,
          &received_message_foo.block
      )).to eq(false)
    end
  end
end
