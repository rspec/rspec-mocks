require "spec_helper"

describe "double" do
  it "is an alias for stub and mock" do
    expect(double()).to be_a(RSpec::Mocks::Mock)
  end

  it "uses 'Double' in failure messages" do
    double = double('name')
    expect {double.foo}.to raise_error(/Double "name" received/)
  end

  describe "deprecated aliases" do
    it "warns if #stub is used" do
      RSpec::Mocks.should_receive(:warn_deprecation).with(/DEPRECATION: use #double instead of #stub/)
      stub("TestDouble")
    end

    it "warns if #mock is used" do
      RSpec::Mocks.should_receive(:warn_deprecation).with(/DEPRECATION: use #double instead of #mock/)
      mock("TestDouble")
    end
  end
end
