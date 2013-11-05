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

  it 'restores standard object methods on reset' do
    dbl = double(:tainted? => true)
    expect(dbl.tainted?).to eq(true)
    reset dbl
    expect(dbl.tainted?).to eq(false)
  end

  it 'does not get string vs symbol messages confused' do
    dbl = double("foo" => 1)
    allow(dbl).to receive(:foo).and_return(2)
    expect(dbl.foo).to eq(2)
    expect { reset dbl }.not_to raise_error
  end
end
