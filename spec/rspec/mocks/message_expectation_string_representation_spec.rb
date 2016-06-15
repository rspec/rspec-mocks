# Add temporary monkey patch to see if this fixes the 1.8.7 travis build
# before we merge the rspec-expectations PR with this fix.
RSpec::Matchers::EnglishPhrasing.class_eval do
  if RUBY_VERSION == '1.8.7'
    # Not sure why, but on travis on 1.8.7 we have gotten these warnings:
    # lib/rspec/matchers/english_phrasing.rb:28: warning: default `to_a' will be obsolete
    # So it appears that `Array` can trigger that (e.g. by calling `to_a` on the passed object?)
    # So here we replace `Kernel#Array` with our own warning-free implementation for 1.8.7.
    # @private
    def self.Array(obj)
      case obj
      when Array then obj
      else [obj]
      end
    end
  end
end

module RSpec
  module Mocks
    RSpec.describe MessageExpectation, "has a nice string representation" do
      let(:test_double) { double }

      example "for a raw message expectation on a test double" do
        expect(allow(test_double).to receive(:foo)).to have_string_representation(
          "#<RSpec::Mocks::MessageExpectation #<Double (anonymous)>.foo(any arguments)>"
        )
      end

      example "for a raw message expectation on a partial double" do
        expect(allow("partial double").to receive(:foo)).to have_string_representation(
          '#<RSpec::Mocks::MessageExpectation "partial double".foo(any arguments)>'
        )
      end

      example "for a message expectation constrained by `with`" do
        expect(allow(test_double).to receive(:foo).with(1, a_kind_of(String), any_args)).to have_string_representation(
          "#<RSpec::Mocks::MessageExpectation #<Double (anonymous)>.foo(1, a kind of String, *(any args))>"
        )
      end

      RSpec::Matchers.define :have_string_representation do |expected_representation|
        match do |object|
          values_match?(expected_representation, object.to_s) && object.to_s == object.inspect
        end

        failure_message do |object|
          "expected string representation: #{expected_representation}\n" \
          " but got string representation: #{object.to_s}"
        end
      end
    end
  end
end
