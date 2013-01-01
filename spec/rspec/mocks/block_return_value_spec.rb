require "spec_helper"

describe "a double declaration with a block handed to:" do
  describe "should_receive" do
    it "returns the value of executing the block" do
      obj = Object.new
      obj.should_receive(:foo) { 'bar' }
      expect(obj.foo).to eq('bar')
    end

    it "works when a multi-return stub has already been set" do
      obj = Object.new
      return_value = Object.new
      obj.stub(:foo).and_return(return_value, nil)
      obj.should_receive(:foo) { return_value }
      expect(obj.foo).to be(return_value)
    end
  end

  describe "stub" do
    it "returns the value of executing the block" do
      obj = Object.new
      obj.stub(:foo) { 'bar' }
      expect(obj.foo).to eq('bar')
    end
  end

  describe "with" do
    it "returns the value of executing the block" do
      obj = Object.new
      obj.stub(:foo).with('baz') { 'bar' }
      expect(obj.foo('baz')).to eq('bar')
    end
  end

  %w[once twice any_number_of_times ordered and_return].each do |method|
    describe method do
      it "returns the value of executing the block" do
        obj = Object.new
        obj.stub(:foo).send(method) { 'bar' }
        expect(obj.foo).to eq('bar')
      end
    end
  end

  describe "times" do
    it "returns the value of executing the block" do
      obj = Object.new
      obj.stub(:foo).at_least(1).times { 'bar' }
      expect(obj.foo('baz')).to eq('bar')
    end
  end
end
