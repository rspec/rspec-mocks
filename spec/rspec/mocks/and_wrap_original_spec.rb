describe "and_wrap_original" do
  context "on a partial double" do
    let(:klass) do
      Class.new do
        def results
          (1..100).to_a
        end
      end
    end

    let(:instance) { klass.new }

    it "allows us to modify the results of the original method" do
      expect {
        allow(instance).to receive(:results).and_wrap_original do |m|
          m.call.first(10)
        end
      }.to change { instance.results.size }.from(100).to(10)
    end

    it "raises a name error if the method does not exist" do
      expect {
        allow(instance).to receive(:no_results).and_wrap_original { |m| m.call }
        instance.no_results
      }.to raise_error NameError
    end

    it "passes in the original method" do
      value = nil
      original_method = instance.method(:results)
      allow(instance).to receive(:results).and_wrap_original { |m| value = m }
      instance.results
      expect(value).to eq original_method
    end

    it "passes along the message arguments" do
      values = nil
      allow(instance).to receive(:results).and_wrap_original { |_, *args| values  = args }
      instance.results(1, 2, 3)
      expect(values).to eq [1, 2, 3]
    end

    it "passes along any supplied block" do
      value = nil
      allow(instance).to receive(:results).and_wrap_original { |&b| value = b }
      instance.results &(block = proc {})
      expect(value).to eq block
    end

    it "ignores previous stubs" do
      allow(instance).to receive(:results) { "results" }
      allow(instance).to receive(:results).and_wrap_original { |m| m.call }
      expect(instance.results).to_not eq "results"
    end

    it "can be constrained by specific arguments" do
      allow(instance).to receive(:results) { :all }
      allow(instance).to receive(:results).with(5).and_wrap_original { |m, n| m.call.first(n) }
      expect(instance.results 5).to eq [1,2,3,4,5]
      expect(instance.results).to eq :all
    end
  end
end
