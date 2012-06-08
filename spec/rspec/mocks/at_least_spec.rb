require 'spec_helper'

module RSpec
  module Mocks
    describe "at_least" do
      before(:each) { @double = double }

      it "fails if method is never called" do
        @double.should_receive(:do_something).at_least(4).times
        lambda do
          @double.rspec_verify
        end.should raise_error(RSpec::Mocks::MockExpectationError)
      end

      it "fails when called less than n times" do
        @double.should_receive(:do_something).at_least(4).times
        @double.do_something
        @double.do_something
        @double.do_something
        lambda do
          @double.rspec_verify
        end.should raise_error(RSpec::Mocks::MockExpectationError)
      end

      it "fails when at least once method is never called" do
        @double.should_receive(:do_something).at_least(:once)
        lambda do
          @double.rspec_verify
        end.should raise_error(RSpec::Mocks::MockExpectationError)
      end

      it "fails when at least twice method is called once" do
        @double.should_receive(:do_something).at_least(:twice)
        @double.do_something
        lambda do
          @double.rspec_verify
        end.should raise_error(RSpec::Mocks::MockExpectationError)
      end

      it "fails when at least twice method is never called" do
        @double.should_receive(:do_something).at_least(:twice)
        lambda do
          @double.rspec_verify
        end.should raise_error(RSpec::Mocks::MockExpectationError)
      end

      it "passes when at least n times method is called exactly n times" do
        @double.should_receive(:do_something).at_least(4).times
        @double.do_something
        @double.do_something
        @double.do_something
        @double.do_something
        @double.rspec_verify
      end

      it "passes when at least n times method is called n plus 1 times" do
        @double.should_receive(:do_something).at_least(4).times
        @double.do_something
        @double.do_something
        @double.do_something
        @double.do_something
        @double.do_something
        @double.rspec_verify
      end

      it "passes when at least once method is called once" do
        @double.should_receive(:do_something).at_least(:once)
        @double.do_something
        @double.rspec_verify
      end

      it "passes when at least once method is called twice" do
        @double.should_receive(:do_something).at_least(:once)
        @double.do_something
        @double.do_something
        @double.rspec_verify
      end

      it "passes when at least twice method is called three times" do
        @double.should_receive(:do_something).at_least(:twice)
        @double.do_something
        @double.do_something
        @double.do_something
        @double.rspec_verify
      end

      it "passes when at least twice method is called twice" do
        @double.should_receive(:do_something).at_least(:twice)
        @double.do_something
        @double.do_something
        @double.rspec_verify
      end

      it "returns the value given by a block when the at least once method is called" do
        @double.should_receive(:to_s).at_least(:once) { "testing" }
        @double.to_s.should eq "testing"
        @double.rspec_verify
      end


      it "raises wrong expected receive count error when the at least 0 method is called" do
        expect{ @double.should_receive(:do_something).at_least(0) }.to raise_error(RSpec::Mocks::MockExpectationError, /expected: at_least\(n\) with n > 0/)
      end
     
      it "uses a stub value if no value set" do
        @double.stub(:do_something => 'foo')
        @double.should_receive(:do_something).at_least(:once)
        @double.do_something.should eq 'foo'
        @double.do_something.should eq 'foo'
      end

      it "prefers its own return value over a stub" do
        @double.stub(:do_something => 'foo')
        @double.should_receive(:do_something).at_least(:once).and_return('bar')
        @double.do_something.should eq 'bar'
        @double.do_something.should eq 'bar'
      end
    end
  end
end
