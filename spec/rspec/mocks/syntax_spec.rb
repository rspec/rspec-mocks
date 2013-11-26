require "spec_helper"

module RSpec::Mocks
  describe Syntax do
    context "when the should syntax is enabled on a non-default syntax host" do
      include_context "with the default mocks syntax"

      it "continues to warn about the should syntax" do
        my_host = Class.new
        expect(RSpec).to receive(:deprecate)
        Syntax.enable_should(my_host)

        o = Object.new
        o.should_receive(:bees)
        o.bees
      end
    end
  end
end
