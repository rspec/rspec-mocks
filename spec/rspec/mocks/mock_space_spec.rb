require 'spec_helper'
require 'rspec/mocks'

module RSpec
  module Mocks
    describe Space do
      let(:space) { RSpec::Mocks::Space.new }
      let(:dbl_1) { Object.new }
      let(:dbl_2) { Object.new }

      before do
        space.ensure_registered(dbl_1)
        space.ensure_registered(dbl_2)
      end

      it "verifies all mocks within" do
        verifies = []

        space.proxy_for(dbl_1).stub(:verify) { verifies << :dbl_1 }
        space.proxy_for(dbl_2).stub(:verify) { verifies << :dbl_2 }

        space.verify_all

        expect(verifies).to match_array([:dbl_1, :dbl_2])
      end

      it "resets all mocks within" do
        resets = []

        space.proxy_for(dbl_1).stub(:reset) { resets << :dbl_1 }
        space.proxy_for(dbl_2).stub(:reset) { resets << :dbl_2 }

        space.reset_all

        expect(resets).to match_array([:dbl_1, :dbl_2])
      end

      it "does not leak mock proxies between examples" do
        expect {
          space.reset_all
        }.to change { space.proxies.size }.to(0)
      end

      it "resets the ordering" do
        space.expectation_ordering.register :some_expectation

        expect {
          space.reset_all
        }.to change { space.expectation_ordering.empty? }.from(false).to(true)
      end

      it "only adds an instance once" do
        m1 = double("mock1")

        expect {
          space.ensure_registered(m1)
        }.to change { space.proxies }

        expect {
          space.ensure_registered(m1)
        }.not_to change { space.proxies }
      end
    end
  end
end

