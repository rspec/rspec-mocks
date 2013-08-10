require "spec_helper"

describe "double" do
  it "is an alias for stub and mock" do
    expect(double()).to be_a(RSpec::Mocks::Mock)
  end

  it "uses 'Double' in failure messages" do
    double = double('name')
    expect {double.foo}.to raise_error(/Double "name" received/)
  end

  it "hides internals in its inspect representation" do
    m = double('cup')
    expect(m.inspect).to match(/#<RSpec::Mocks::Mock:0x[a-f0-9.]+ @name="cup">/)
  end
end
