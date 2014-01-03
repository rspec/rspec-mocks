require 'spec_helper'

module RSpec
  module Mocks
    describe "failing MockArgumentMatchers" do
      before(:each) do
        @double = double("double")
        @reporter = double("reporter").as_null_object
      end

      after(:each) do
        reset @double
      end

      it "rejects non boolean" do
        @double.should_receive(:random_call).with(boolean())
        expect do
          @double.random_call("false")
        end.to raise_error(RSpec::Mocks::MockExpectationError)
      end

      it "rejects non numeric" do
        @double.should_receive(:random_call).with(an_instance_of(Numeric))
        expect do
          @double.random_call("1")
        end.to raise_error(RSpec::Mocks::MockExpectationError)
      end

      it "rejects non string" do
        @double.should_receive(:random_call).with(an_instance_of(String))
        expect do
          @double.random_call(123)
        end.to raise_error(RSpec::Mocks::MockExpectationError)
      end

      it "rejects goose when expecting a duck" do
        @double.should_receive(:random_call).with(duck_type(:abs, :div))
        expect { @double.random_call("I don't respond to :abs or :div") }.to raise_error(RSpec::Mocks::MockExpectationError)
      end

      it "fails if regexp does not match submitted string" do
        @double.should_receive(:random_call).with(/bcd/)
        expect { @double.random_call("abc") }.to raise_error(RSpec::Mocks::MockExpectationError)
      end

      it "fails if regexp does not match submitted regexp" do
        @double.should_receive(:random_call).with(/bcd/)
        expect { @double.random_call(/bcde/) }.to raise_error(RSpec::Mocks::MockExpectationError)
      end

      it "fails for a hash w/ wrong values" do
        @double.should_receive(:random_call).with(:a => "b", :c => "d")
        expect do
          @double.random_call(:a => "b", :c => "e")
        end.to raise_error(RSpec::Mocks::MockExpectationError, /Double "double" received :random_call with unexpected arguments\n  expected: \(\{(:a=>\"b\", :c=>\"d\"|:c=>\"d\", :a=>\"b\")\}\)\n       got: \(\{(:a=>\"b\", :c=>\"e\"|:c=>\"e\", :a=>\"b\")\}\)/)
      end

      it "fails for a hash w/ wrong keys" do
        @double.should_receive(:random_call).with(:a => "b", :c => "d")
        expect do
          @double.random_call("a" => "b", "c" => "d")
        end.to raise_error(RSpec::Mocks::MockExpectationError, /Double "double" received :random_call with unexpected arguments\n  expected: \(\{(:a=>\"b\", :c=>\"d\"|:c=>\"d\", :a=>\"b\")\}\)\n       got: \(\{(\"a\"=>\"b\", \"c\"=>\"d\"|\"c\"=>\"d\", \"a\"=>\"b\")\}\)/)
      end

      it "matches against a Matcher" do
        # This spec is generating warnings on 1.8.7, not sure why so
        # this does with_isolated_stderr to kill them. @samphippen 3rd Jan 2013.
        expect do
          @double.should_receive(:msg).with(equal(3))
          with_isolated_stderr { @double.msg(37) }
        end.to raise_error(RSpec::Mocks::MockExpectationError, "Double \"double\" received :msg with unexpected arguments\n  expected: (equal 3)\n       got: (37)")
      end

      it "fails no_args with one arg" do
        expect do
          @double.should_receive(:msg).with(no_args)
          @double.msg(37)
        end.to raise_error(RSpec::Mocks::MockExpectationError, "Double \"double\" received :msg with unexpected arguments\n  expected: (no args)\n       got: (37)")
      end

      it "fails hash_including with missing key" do
         expect do
           @double.should_receive(:msg).with(hash_including(:a => 1))
           @double.msg({})
         end.to raise_error(RSpec::Mocks::MockExpectationError, "Double \"double\" received :msg with unexpected arguments\n  expected: (hash_including(:a=>1))\n       got: ({})")
      end

      it "fails array_including when args aren't array" do
         expect do
           @double.should_receive(:msg).with(array_including(1,2,3))
           @double.msg(1,2,3)
         end.to raise_error(/array_including\(1,2,3\)/)
      end

      it "fails array_including when arg doesn't contain all elements" do
         expect do
           @double.should_receive(:msg).with(array_including(1,2,3))
           @double.msg(1,2)
         end.to raise_error(/array_including\(1,2,3\)/)
      end

      it "fails with zero arguments" do
        expect do
          @double.should_receive(:msg).with {|arg| expect(arg).to eq :received }
        end.to raise_error(ArgumentError, /must have at least one argument/)
      end

      it "fails when given an arbitrary object that returns false from #===" do
        matcher = double
        matcher.should_receive(:===).with(4).at_least(:once).and_return(false)

        @double.should_receive(:foo).with(matcher)

        expect {
          @double.foo(4)
        }.to raise_error(RSpec::Mocks::MockExpectationError)
      end

      it "fails with sensible message when args respond to #description" do
        arg = Class.new do
          def description
          end

          def inspect
            "my_thing"
          end
        end.new

        expect do
          @double.should_receive(:msg).with(3)
          @double.msg arg
        end.to raise_error(RSpec::Mocks::MockExpectationError, "Double \"double\" received :msg with unexpected arguments\n  expected: (3)\n       got: (my_thing)")
      end

      it "fails with sensible message when arg#description is nil" do
        arg = Class.new do
          def description
          end

          def inspect
            "my_thing"
          end
        end.new

        expect do
          @double.should_receive(:msg).with(arg)
          @double.msg 3
        end.to raise_error(RSpec::Mocks::MockExpectationError, "Double \"double\" received :msg with unexpected arguments\n  expected: (my_thing)\n       got: (3)")
      end

      it "fails with sensible message when arg#description is blank" do
        arg = Class.new do
          def description
            ""
          end

          def inspect
            "my_thing"
          end
        end.new

        expect do
          @double.should_receive(:msg).with(arg)
          @double.msg 3
        end.to raise_error(RSpec::Mocks::MockExpectationError, "Double \"double\" received :msg with unexpected arguments\n  expected: (my_thing)\n       got: (3)")
      end

      it "fails a class against an unrelated class" do
        @double.should_receive(:foo).with(Fixnum)
        expect {
          @double.foo(Hash)
        }.to raise_error(RSpec::Mocks::MockExpectationError)
      end

      it "fails a class against an object of a different type" do
        @double.should_receive(:foo).with(Fixnum)

        expect {
          @double.foo(3.2)
        }.to raise_error(RSpec::Mocks::MockExpectationError)
      end
    end
  end
end
