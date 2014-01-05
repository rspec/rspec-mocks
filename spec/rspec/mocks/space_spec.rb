require 'spec_helper'

module RSpec::Mocks
  describe Space do

    describe "#proxies_of(klass)" do
      let(:space) { Space.new }

      it 'returns proxies' do
        space.proxy_for("")
        expect(space.proxies_of(String).map(&:class)).to eq([PartialDoubleProxy])
      end

      it 'returns only the proxies whose object is an instance of the given class' do
        grandparent_class = Class.new
        parent_class      = Class.new(grandparent_class)
        child_class       = Class.new(parent_class)

        grandparent = grandparent_class.new
        parent      = parent_class.new
        child       = child_class.new

        space.proxy_for(grandparent)

        parent_proxy      = space.proxy_for(parent)
        child_proxy       = space.proxy_for(child)

        expect(space.proxies_of(parent_class)).to match_array([parent_proxy, child_proxy])
      end
    end

    it 'can be diffed in a failure when it has references to an error generator via a proxy' do
      space1 = Space.new
      space2 = Space.new

      space1.proxy_for("")
      space2.proxy_for("")

      expect {
        expect(space1).to eq(space2)
      }.to raise_error(RSpec::Expectations::ExpectationNotMetError, /Diff/)
    end

  end
end
