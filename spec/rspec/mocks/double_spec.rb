require "spec_helper"

describe "double" do
  it "is an alias for stub and mock" do
    double().should be_a(RSpec::Mocks::Mock)
  end

  it "uses 'Double' in failure messages" do
    double = double('name')
    expect {double.foo}.to raise_error(/Double "name" received/)
  end

  it "allows stubbing of chained methods" do
    obj = double(:obj, 'foo.bar' => 'baz')
    obj.foo.bar.should == 'baz'
  end
end
