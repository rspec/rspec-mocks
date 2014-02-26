module RSpec
  module Mocks
    describe "Passing argument matchers" do
      before(:each) do
        @double = double('double')
        allow(Kernel).to receive(:warn)
      end

      after(:each) do
        verify @double
      end

      context "handling argument matchers" do
        it "accepts true as boolean()" do
          expect(@double).to receive(:random_call).with(boolean())
          @double.random_call(true)
        end

        it "accepts false as boolean()" do
          expect(@double).to receive(:random_call).with(boolean())
          @double.random_call(false)
        end

        it "accepts fixnum as kind_of(Numeric)" do
          expect(@double).to receive(:random_call).with(kind_of(Numeric))
          @double.random_call(1)
        end

        it "accepts float as an_instance_of(Numeric)" do
          expect(@double).to receive(:random_call).with(kind_of(Numeric))
          @double.random_call(1.5)
        end

        it "accepts fixnum as instance_of(Fixnum)" do
          expect(@double).to receive(:random_call).with(instance_of(Fixnum))
          @double.random_call(1)
        end

        it "does NOT accept fixnum as instance_of(Numeric)" do
          expect(@double).not_to receive(:random_call).with(instance_of(Numeric))
          @double.random_call(1)
        end

        it "does NOT accept float as instance_of(Numeric)" do
          expect(@double).not_to receive(:random_call).with(instance_of(Numeric))
          @double.random_call(1.5)
        end

        it "accepts string as anything()" do
          expect(@double).to receive(:random_call).with("a", anything(), "c")
          @double.random_call("a", "whatever", "c")
        end

        it "matches duck type with one method" do
          expect(@double).to receive(:random_call).with(duck_type(:length))
          @double.random_call([])
        end

        it "matches duck type with two methods" do
          expect(@double).to receive(:random_call).with(duck_type(:abs, :div))
          @double.random_call(1)
        end

        it "matches no args against any_args()" do
          expect(@double).to receive(:random_call).with(any_args)
          @double.random_call()
        end

        it "matches one arg against any_args()" do
          expect(@double).to receive(:random_call).with(any_args)
          @double.random_call("a string")
        end

        it "matches no args against no_args()" do
          expect(@double).to receive(:random_call).with(no_args)
          @double.random_call()
        end

        it "matches hash with hash_including same hash" do
          expect(@double).to receive(:random_call).with(hash_including(:a => 1))
          @double.random_call(:a => 1)
        end

        it "matches array with array_including same array" do
          expect(@double).to receive(:random_call).with(array_including(1,2))
          @double.random_call([1,2])
        end

        it "matches any arbitrary object using #===" do
          matcher = double
          expect(matcher).to receive(:===).with(4).and_return(true)

          expect(@double).to receive(:foo).with(matcher)
          @double.foo(4)
        end
      end

      context "handling non-matcher arguments" do
        it "matches non special symbol (can be removed when deprecated symbols are removed)" do
          expect(@double).to receive(:random_call).with(:some_symbol)
          @double.random_call(:some_symbol)
        end

        it "matches string against regexp" do
          expect(@double).to receive(:random_call).with(/bcd/)
          @double.random_call("abcde")
        end

        it "matches regexp against regexp" do
          expect(@double).to receive(:random_call).with(/bcd/)
          @double.random_call(/bcd/)
        end

        it "matches against a hash submitted and received by value" do
          expect(@double).to receive(:random_call).with(:a => "a", :b => "b")
          @double.random_call(:a => "a", :b => "b")
        end

        it "matches against a hash submitted by reference and received by value" do
          opts = {:a => "a", :b => "b"}
          expect(@double).to receive(:random_call).with(opts)
          @double.random_call(:a => "a", :b => "b")
        end

        it "matches against a hash submitted by value and received by reference" do
          opts = {:a => "a", :b => "b"}
          expect(@double).to receive(:random_call).with(:a => "a", :b => "b")
          @double.random_call(opts)
        end

        it "matches a class against itself" do
          expect(@double).to receive(:foo).with(Fixnum)
          @double.foo(Fixnum)
        end

        it "matches a class against an instance of itself" do
          expect(@double).to receive(:foo).with(Fixnum)
          @double.foo(3)
        end
      end
    end
  end
end
