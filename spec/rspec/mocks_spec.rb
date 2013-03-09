require "spec_helper"

describe RSpec::Mocks do
  describe "::setup" do
    context "with an existing Mocks::Space" do
      before do
        @orig_space = RSpec::Mocks::space
      end

      after do
        RSpec::Mocks::space = @orig_space
      end

      it "memoizes the space" do
        RSpec::Mocks::setup(Object.new)
        space = RSpec::Mocks::space
        RSpec::Mocks::setup(Object.new)
        expect(RSpec::Mocks::space).to equal(space)
      end
    end

    context "with no pre-existing Mocks::Space" do
      it "initializes a Mocks::Space" do
        RSpec::Mocks::space = nil
        RSpec::Mocks::setup(Object.new)
        expect(RSpec::Mocks::space).not_to be_nil
      end
    end
  end

  describe "::verify" do
    it "delegates to the space" do
      foo = double
      foo.should_receive(:bar)
      expect do
        RSpec::Mocks::verify
      end.to raise_error(RSpec::Mocks::MockExpectationError)
    end
  end

  describe "::teardown" do
    it "delegates to the space" do
      foo = double
      foo.should_receive(:bar)
      RSpec::Mocks::teardown
      expect do
        foo.bar
      end.to raise_error(/received unexpected message/)
    end
  end

  describe ".configuration" do
    it 'returns a memoized configuration instance' do
      expect(RSpec::Mocks.configuration).to be_a(RSpec::Mocks::Configuration)
      expect(RSpec::Mocks.configuration).to be(RSpec::Mocks.configuration)
    end
  end

  describe "ArgumentMatchers not overriding let definitions" do
    WithMatchers = Class.new { include RSpec::Mocks::ArgumentMatchers }
    methods = WithMatchers.new.methods - Object.new.methods

    methods.each do |method|
      let(method) { :a_thing }

      it "doesn't override a let named #{ method }" do
        expect(send(method)).to be(:a_thing)
      end
    end
  end
end

