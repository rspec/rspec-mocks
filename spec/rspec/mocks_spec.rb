require "spec_helper"

describe RSpec::Mocks do
  describe "::verify" do
    it "delegates to the space" do
      foo = double
      foo.should_receive(:bar)
      expect do
        RSpec::Mocks::verify
      end.to raise_error(RSpec::Mocks::MockExpectationError)

      RSpec::Mocks.teardown # so the mocks aren't re-verified after this example
    end
  end

  describe "::teardown" do
    it "resets method stubs" do
      string = "foo"
      allow(string).to receive(:bar)
      RSpec::Mocks.teardown
      expect { string.bar }.to raise_error(NoMethodError)
    end
  end

  describe ".configuration" do
    it 'returns a memoized configuration instance' do
      expect(RSpec::Mocks.configuration).to be_a(RSpec::Mocks::Configuration)
      expect(RSpec::Mocks.configuration).to be(RSpec::Mocks.configuration)
    end
  end

  context "when there is a `let` declaration that overrides an argument matcher" do
    let(:boolean) { :from_let }

    before do
      expect(RSpec::Mocks::ArgumentMatchers.method_defined?(:boolean)).to be true
    end

    it 'allows the `let` definition to win' do
      expect(boolean).to eq(:from_let)
    end
  end
end

