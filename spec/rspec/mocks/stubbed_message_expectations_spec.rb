require 'spec_helper'

describe "expection set on previously stubbed method" do
  it "fails if message is not received after expectation is set" do
    double = double(:msg => nil)
    double.msg
    double.should_receive(:msg)
    expect { verify double }.to raise_error(RSpec::Mocks::MockExpectationError)
  end

  it "outputs arguments of similar calls" do
    double = double('double', :foo => true)
    double.should_receive(:foo).with('first')
    double.foo('second')
    double.foo('third')
    expect {
      verify double
    }.to raise_error(%Q|Double "double" received :foo with unexpected arguments\n  expected: ("first")\n       got: ("second"), ("third")|)
    reset double
  end

  context "with argument constraint on stub" do
    it "matches any args if no arg constraint set on expectation" do
      double = double("mock")
      double.stub(:foo).with(3).and_return("stub")
      double.should_receive(:foo).at_least(:once).and_return("expectation")
      double.foo
      verify double
    end

    it "matches specific args set on expectation" do
      double = double("mock")
      double.stub(:foo).with(3).and_return("stub")
      double.should_receive(:foo).at_least(:once).with(4).and_return("expectation")
      double.foo(4)
      verify double
    end

    it "fails if expectation's arg constraint is not met" do
      double = double("mock")
      double.stub(:foo).with(3).and_return("stub")
      double.should_receive(:foo).at_least(:once).with(4).and_return("expectation")
      double.foo(3)
      expect { verify double }.to raise_error(/expected: \(4\)\s+got: \(3\)/)
    end

    it 'distinguishes between individual values and arrays properly' do
      dbl = double
      dbl.stub(:foo).with('a', ['b'])

      expect {
        dbl.foo(['a'], 'b')
      }.to raise_error { |e|
        expect(e.message).to include('expected: ("a", ["b"])', 'got: (["a"], "b")')
      }
    end

    describe "when using a short-hand specific argument constraint method" do
      context "for a stubbed method" do
        it 'assumes "anything" for all arguments other than the specified argument' do
          [:first, :second, :third, :fourth, :fifth, :sixth, :seventh, :eigth, :ninth] \
            .each_with_index do |interval, index|

            with_x_argument = "with_#{interval}_argument"

            dbl = double
            params = [anything] * 10
            dbl.stub(:test).with(*params)

            dbl.should_receive(:test).send(with_x_argument, 1)

            expect { verify dbl }.to raise_error
              /\((#<.+AnyArgMatcher.+>, ){#{index}}1(, #<.+AnyArgMatcher.+>){#{9-index}}\)/
          end
        end
      end

      context "for a concrete method" do
        class FakeConcreteObject
          def concrete_method(p1, p2, p3, p4, p5, p6, p7, p8, p9, p10)
          end
        end

        it 'assumes "anything" for all arguments other than the specified argument' do
          [:first, :second, :third, :fourth, :fifth, :sixth, :seventh, :eigth, :ninth] \
            .each_with_index do |interval, index|

            with_x_argument = "with_#{interval}_argument"

            obj = FakeConcreteObject.new

            obj.should_receive(:concrete_method).send(with_x_argument, 1)

            expect { verify obj }.to raise_error
              /\((#<.+AnyArgMatcher.+>, ){#{index}}1(, #<.+AnyArgMatcher.+>){#{9-index}}\)/
          end
        end
      end
    end
  end
end
