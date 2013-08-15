require "spec_helper"

describe "double" do
  it "is an alias for stub and mock" do
    expect(double()).to be_a(RSpec::Mocks::Mock)
  end

  it "uses 'Double' in failure messages" do
    double = double('name')
    expect {double.foo}.to raise_error(/Double "name" received/)
  end

  it 'restores standard object methods on reset' do
    dbl = double(:tainted? => true)
    expect(dbl.tainted?).to eq(true)
    reset dbl
    expect(dbl.tainted?).to eq(false)
  end
end
