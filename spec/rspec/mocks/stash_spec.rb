require 'spec_helper'

module RSpec
  module Mocks

    describe "only stashing the original method" do
      let(:klass) do
        Class.new do
          def self.foo(arg)
            :original_value
          end
        end
      end

      it "keeps the original method intact after multiple expectations are added on the same method" do
        klass.should_receive(:foo).with(:fizbaz).and_return(:wowwow)
        klass.should_receive(:foo).with(:bazbar).and_return(:okay)

        klass.foo(:fizbaz)
        klass.foo(:bazbar)
        klass.rspec_verify

        klass.rspec_reset
        expect(klass.foo(:yeah)).to equal(:original_value)
      end
    end

    describe "when a class method is aliased on a subclass and the method is mocked" do
      let(:klass) do
        Class.new do
          class << self
            alias alternate_new new
          end
        end
      end

      it "restores the original aliased public method" do
        klass = Class.new do
          class << self
            alias alternate_new new
          end
        end

        klass.should_receive(:alternate_new)
        expect(klass.alternate_new).to be_nil

        klass.rspec_verify

        klass.rspec_reset
        expect(klass.alternate_new).to be_an_instance_of(klass)
      end
    end
  end
end
