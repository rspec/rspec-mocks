require 'spec_helper'

describe "AnyNumberOfTimes" do
  it "is gone" do
    expect(RSpec::Mocks::MessageExpectation.instance_methods).not_to include(:any_number_of_times)
  end
end
