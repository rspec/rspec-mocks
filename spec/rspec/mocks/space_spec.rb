require 'spec_helper'

module RSpec::Mocks
  describe Space do
    let(:space) { Space.new }


    describe "#proxies_of(klass)" do
      it 'returns proxies' do
        space.proxy_for("")
        expect(space.proxies_of(String).map(&:class)).to eq([PartialDoubleProxy])
      end

      def create_generations
        grandparent_class = Class.new
        parent_class      = Class.new(grandparent_class)
        child_class       = Class.new(parent_class)

        grandparent = grandparent_class.new
        parent      = parent_class.new
        child       = child_class.new

        return grandparent, parent, child
      end

      it 'returns only the proxies whose object is an instance of the given class' do
        grandparent, parent, child = create_generations

        space.proxy_for(grandparent)

        parent_proxy = space.proxy_for(parent)
        child_proxy  = space.proxy_for(child)

        expect(space.proxies_of(parent.class)).to contain_exactly(parent_proxy, child_proxy)
      end

      it 'looks in the parent space for matching proxies' do
        _, parent, child = create_generations

        parent_proxy = space.proxy_for(parent)
        subspace     = space.new_scope
        child_proxy  = subspace.proxy_for(child)

        expect(subspace.proxies_of(parent.class)).to contain_exactly(parent_proxy, child_proxy)
      end
    end

    it 'tracks proxies in parent and child space separately' do
      proxy1   = space.proxy_for(Object.new)
      subspace = space.new_scope
      proxy2   = subspace.proxy_for(Object.new)

      expect(space.proxies.values).to include(proxy1)
      expect(space.proxies.values).not_to include(proxy2)

      expect(subspace.proxies.values).to include(proxy2)
      expect(subspace.proxies.values).not_to include(proxy1)
    end

    [:ensure_registered, :proxy_for].each do |method|
      describe "##{method}" do
        define_method :get_proxy do |space, object|
          space.__send__(method, object)
        end

        it 'returns the proxy for the given object' do
          obj1 = Object.new
          obj2 = Object.new

          expect(get_proxy(space, obj1)).to equal(get_proxy(space, obj1))
          expect(get_proxy(space, obj2)).to equal(get_proxy(space, obj2))
          expect(get_proxy(space, obj1)).not_to equal(get_proxy(space, obj2))
        end

        it 'can stil return a proxy from a parent context' do
          proxy    = get_proxy(space, Object)
          subspace = space.new_scope

          expect(get_proxy(subspace, Object)).to equal(proxy)
        end

        it "does not store a parent's proxy in the child space" do
          get_proxy(space, Object)
          subspace = space.new_scope

          expect {
            get_proxy(subspace, Object)
          }.not_to change { subspace.proxies }.from({})
        end
      end
    end

    describe "#registered?" do
      it 'returns true if registered in this space' do
        space.ensure_registered(Object)
        expect(space).to be_registered(Object)
      end

      it 'returns true if registered in a parent space' do
        space.ensure_registered(Object)
        expect(space.new_scope).to be_registered(Object)
      end

      it 'returns false if not registered in this or a parent space' do
        expect(space.new_scope).not_to be_registered(Object)
      end
    end

    describe "#constant_mutator_for" do
      it 'returns the mutator for the given const name' do
        space = RSpec::Mocks.space
        stub_const("Foo", 3)
        stub_const("Bar", 4)

        expect(space.constant_mutator_for("Foo")).to equal(space.constant_mutator_for("Foo"))
        expect(space.constant_mutator_for("Bar")).to equal(space.constant_mutator_for("Bar"))
        expect(space.constant_mutator_for("Foo")).not_to equal(space.constant_mutator_for("Bar"))
      end

      it 'can stil return a mutator from a parent context' do
        space = RSpec::Mocks.space

        stub_const("Foo", 3)
        mutator = space.constant_mutator_for("Foo")

        in_new_space_scope do
          subspace = RSpec::Mocks.space
          expect(subspace.constant_mutator_for("Foo")).to equal(mutator)
        end
      end
    end

    describe "#any_instance_recorder_for" do
      it 'returns the recorder for the given class' do
        expect(space.any_instance_recorder_for(String)).to equal(space.any_instance_recorder_for(String))
        expect(space.any_instance_recorder_for(Symbol)).to equal(space.any_instance_recorder_for(Symbol))
        expect(space.any_instance_recorder_for(String)).not_to equal(space.any_instance_recorder_for(Symbol))
      end

      it 'can stil return a recorder from a parent context' do
        recorder = space.any_instance_recorder_for(String)
        subspace = space.new_scope

        expect(subspace.any_instance_recorder_for(String)).to equal(recorder)
      end

      it "does not store a parent's proxy in the child space" do
        space.any_instance_recorder_for(String)
        subspace = space.new_scope

        expect {
          subspace.any_instance_recorder_for(String)
        }.not_to change { subspace.any_instance_recorders }.from({})
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

    def in_new_space_scope
      RSpec::Mocks.setup
      yield
    ensure
      RSpec::Mocks.teardown
    end
  end
end
