require "spec_helper"
require "delegate"

describe "Stubbing/mocking methods in before(:all) blocks" do
  old_rspec = nil

  shared_examples_for "A stub/mock in a before(:all) block" do
    the_error = nil
    before(:all) do
      begin
        use_rspec_mocks
      rescue
        the_error = $!
      end
    end

    it "raises an error with a useful message" do
      expect(the_error).to be_a_kind_of(RSpec::Mocks::OutsideOfExampleError)

      expect(the_error.message).to match(/The use of doubles or partial doubles from rspec-mocks outside of the per-test lifecycle is not supported./)
    end
  end

  describe "#stub" do
    it_behaves_like "A stub/mock in a before(:all) block" do
      def use_rspec_mocks
        Object.stub(:foo)
      end
    end
  end

  describe "#unstub" do
    it_behaves_like "A stub/mock in a before(:all) block" do
      def use_rspec_mocks
        Object.unstub(:foo)
      end
    end
  end

  describe "#should_receive" do
    it_behaves_like "A stub/mock in a before(:all) block" do
      def use_rspec_mocks
        Object.should_receive(:foo)
      end
    end
  end

  describe "#should_not_receive" do
    it_behaves_like "A stub/mock in a before(:all) block" do
      def use_rspec_mocks
        Object.should_not_receive(:foo)
      end
    end
  end

  describe "#any_instance" do
    it_behaves_like "A stub/mock in a before(:all) block" do
      def use_rspec_mocks
        Object.any_instance.should_receive(:foo)
      end
    end
  end

  describe "#stub_chain" do
    it_behaves_like "A stub/mock in a before(:all) block" do
      def use_rspec_mocks
        Object.stub_chain(:foo)
      end
    end
  end

  describe "#expect(...).to receive" do
    it_behaves_like "A stub/mock in a before(:all) block" do
      def use_rspec_mocks
        expect(Object).to receive(:foo)
      end
    end
  end

  describe "#allow(...).to receive" do
    it_behaves_like "A stub/mock in a before(:all) block" do
      def use_rspec_mocks
        allow(Object).to receive(:foo)
      end
    end
  end

  describe "#expect_any_instance_of(...).to receive" do
    it_behaves_like "A stub/mock in a before(:all) block" do
      def use_rspec_mocks
        expect_any_instance_of(Object).to receive(:foo)
      end
    end
  end

  describe "#allow_any_instance_of(...).to receive" do
    it_behaves_like "A stub/mock in a before(:all) block" do
      def use_rspec_mocks
        allow_any_instance_of(Object).to receive(:foo)
      end
    end
  end
end
