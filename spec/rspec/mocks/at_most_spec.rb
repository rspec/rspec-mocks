module RSpec
  module Mocks
    describe "at_most" do
      before(:each) do
        @double = double
      end

      it "passes when at_most(n) is called exactly n times" do
        expect(@double).to receive(:do_something).at_most(2).times
        @double.do_something
        @double.do_something
        verify @double
      end

      it "passes when at_most(n) is called less than n times" do
        expect(@double).to receive(:do_something).at_most(2).times
        @double.do_something
        verify @double
      end

      it "passes when at_most(n) is never called" do
        expect(@double).to receive(:do_something).at_most(2).times
        verify @double
      end

      it "passes when at_most(:once) is called once" do
        expect(@double).to receive(:do_something).at_most(:once)
        @double.do_something
        verify @double
      end

      it "passes when at_most(:once) is never called" do
        expect(@double).to receive(:do_something).at_most(:once)
        verify @double
      end

      it "passes when at_most(:twice) is called once" do
        expect(@double).to receive(:do_something).at_most(:twice)
        @double.do_something
        verify @double
      end

      it "passes when at_most(:twice) is called twice" do
        expect(@double).to receive(:do_something).at_most(:twice)
        @double.do_something
        @double.do_something
        verify @double
      end

      it "passes when at_most(:twice) is never called" do
        expect(@double).to receive(:do_something).at_most(:twice)
        verify @double
      end

      it "passes when at_most(:thrice) is called less than three times" do
        expect(@double).to receive(:do_something).at_most(:thrice)
        @double.do_something
        verify @double
      end

      it "passes when at_most(:thrice) is called thrice" do
        expect(@double).to receive(:do_something).at_most(:thrice)
        @double.do_something
        @double.do_something
        @double.do_something
        verify @double
      end

      it "returns the value given by a block when at_most(:once) method is called" do
        expect(@double).to receive(:to_s).at_most(:once) { "testing" }
        expect(@double.to_s).to eq "testing"
        verify @double
      end

      it "fails fast when at_most(n) times method is called n plus 1 times" do
        expect(@double).to receive(:do_something).at_most(2).times
        @double.do_something
        @double.do_something
        expect {
          @double.do_something
        }.to raise_error(/expected: at most 2 times.*received: 3 times/m)
      end

      it "fails fast when at_most(:once) and is called twice" do
        expect(@double).to receive(:do_something).at_most(:once)
        @double.do_something
        expect {
          @double.do_something
        }.to raise_error(/expected: at most 1 time.*received: 2 times/m)
      end

      it "fails fast when at_most(:twice) and is called three times" do
        expect(@double).to receive(:do_something).at_most(:twice)
        @double.do_something
        @double.do_something
        expect {
          @double.do_something
        }.to raise_error(/expected: at most 2 times.*received: 3 times/m)
      end

      it "fails fast when at_most(:thrice) and is called four times" do
        expect(@double).to receive(:do_something).at_most(:thrice)
        @double.do_something
        @double.do_something
        @double.do_something
        expect {
          @double.do_something
        }.to raise_error(/expected: at most 3 times.*received: 4 times/m)
      end

    end
  end
end
