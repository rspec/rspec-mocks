RSpec.describe "Using the legacy should syntax" do
  include_context "with syntax", [:should, :expect]

  describe "#stub" do
    it "supports options" do
      double.stub(:foo, :expected_from => "bar")
    end

    it 'returns `nil` from all terminal actions to discourage further configuration' do
      expect(double.stub(:foo).and_return(1)).to be_nil
      expect(double.stub(:foo).and_raise("boom")).to be_nil
      expect(double.stub(:foo).and_throw(:foo)).to be_nil
    end
  end

  describe "#should_receive" do
    context "with an options hash" do
      it "reports the file and line submitted with :expected_from" do
        begin
          mock = RSpec::Mocks::Double.new("a mock")
          mock.should_receive(:message, :expected_from => "/path/to/blah.ext:37")
          verify mock
        rescue Exception => e
        ensure
          expect(e.backtrace.to_s).to match(/\/path\/to\/blah.ext:37/m)
        end
      end

      it "uses the message supplied with :message" do
        expect {
          m = RSpec::Mocks::Double.new("a mock")
          m.should_receive(:message, :message => "recebi nada")
          verify m
        }.to raise_error("recebi nada")
      end

      it "uses the message supplied with :message after a similar stub" do
        expect {
          m = RSpec::Mocks::Double.new("a mock")
          m.stub(:message)
          m.should_receive(:message, :message => "from mock")
          verify m
        }.to raise_error("from mock")
      end
    end
  end

  describe "#should_not_receive" do
    it "returns a negative message expectation" do
      expect(Object.new.should_not_receive(:foobar)).to be_negative
    end
  end
end

RSpec.context "with default syntax configuration" do
  orig_syntax = nil

  before(:all) { orig_syntax = RSpec::Mocks.configuration.syntax }
  after(:all)  { RSpec::Mocks.configuration.syntax = orig_syntax }
  before       { RSpec::Mocks.configuration.reset_syntaxes_to_default }

  let(:expected_arguments) {
    [
      /Using.*without explicitly enabling/,
      {:replacement=>"the new `:expect` syntax or explicitly enable `:should`"}
    ]
  }

  it "it warns about should once, regardless of how many times it is called" do
    expect(RSpec).to receive(:deprecate).with(*expected_arguments)
    o = Object.new
    o2 = Object.new
    o.should_receive(:bees)
    o2.should_receive(:bees)

    o.bees
    o2.bees
  end

  it "warns about should not once, regardless of how many times it is called" do
    expect(RSpec).to receive(:deprecate).with(*expected_arguments)
    o = Object.new
    o2 = Object.new
    o.should_not_receive(:bees)
    o2.should_not_receive(:bees)
  end

  it "warns about stubbing once, regardless of how many times it is called" do
    expect(RSpec).to receive(:deprecate).with(*expected_arguments)
    o = Object.new
    o2 = Object.new

    o.stub(:faces)
    o2.stub(:faces)
  end

  it "warns about unstubbing once, regardless of how many times it is called" do
    expect(RSpec).to receive(:deprecate).with(/Using.*without explicitly enabling/,
      {:replacement => "`allow(...).to_receive(...).and_call_original` or explicitly enable `:should`"})
    o = Object.new
    o2 = Object.new

    allow(o).to receive(:faces)
    allow(o2).to receive(:faces)

    o.unstub(:faces)
    o2.unstub(:faces)
  end


  it "doesn't warn about stubbing after a reset and setting should" do
    expect(RSpec).not_to receive(:deprecate)
    RSpec::Mocks.configuration.reset_syntaxes_to_default
    RSpec::Mocks.configuration.syntax = :should
    o = Object.new
    o2 = Object.new
    o.stub(:faces)
    o2.stub(:faces)
  end

  it "includes the call site in the deprecation warning" do
    obj = Object.new
    expect_deprecation_with_call_site(__FILE__, __LINE__ + 1)
    obj.stub(:faces)
  end
end

RSpec.context "when the should syntax is enabled on a non-default syntax host" do
  include_context "with the default mocks syntax"

  it "continues to warn about the should syntax" do
    my_host = Class.new
    expect(RSpec).to receive(:deprecate)
    RSpec::Mocks::Syntax.enable_should(my_host)

    o = Object.new
    o.should_receive(:bees)
    o.bees
  end
end
