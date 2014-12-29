RSpec.describe "expection set on previously stubbed method" do
  it "fails if message is not received after expectation is set" do
    dbl = double(:msg => nil)
    dbl.msg
    expect(dbl).to receive(:msg)
    expect { verify dbl }.to raise_error(RSpec::Mocks::MockExpectationError)
  end

  it "outputs arguments of similar calls" do
    dbl = double('double', :foo => true)
    expect(dbl).to receive(:foo).with('first')
    dbl.foo('second')
    dbl.foo('third')
    expect {
      verify dbl
    }.to raise_error(%Q|Double "double" received :foo with unexpected arguments\n  expected: ("first")\n       got: ("second"), ("third")|)
    reset dbl
  end

  context "with argument constraint on stub" do
    it "matches any args if no arg constraint set on expectation" do
      dbl = double("mock")
      allow(dbl).to receive(:foo).with(3).and_return("stub")
      expect(dbl).to receive(:foo).at_least(:once).and_return("expectation")
      dbl.foo
      verify dbl
    end

    it "matches specific args set on expectation" do
      dbl = double("mock")
      allow(dbl).to receive(:foo).with(3).and_return("stub")
      expect(dbl).to receive(:foo).at_least(:once).with(4).and_return("expectation")
      dbl.foo(4)
      verify dbl
    end

    it "fails if expectation's arg constraint is not met" do
      dbl = double("mock")
      allow(dbl).to receive(:foo).with(3).and_return("stub")
      expect(dbl).to receive(:foo).at_least(:once).with(4).and_return("expectation")
      dbl.foo(3)
      expect { verify dbl }.to raise_error(/expected: \(4\)\s+got: \(3\)/)
    end

    it 'distinguishes between individual values and arrays properly' do
      dbl = double
      allow(dbl).to receive(:foo).with('a', ['b'])

      expect {
        dbl.foo(['a'], 'b')
      }.to raise_error { |e|
        expect(e.message).to include('expected: ("a", ["b"])', 'got: (["a"], "b")')
      }
    end
  end
end
