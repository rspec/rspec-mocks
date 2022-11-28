require "spec_helper"
require "pp"

RSpec.describe "Diffs printed when arguments don't match" do
  include RSpec::Support::Spec::DiffHelpers

  before do
    allow(RSpec::Mocks.configuration).to receive(:color?).and_return(false)
  end

  context "with a non matcher object" do
    it "does not print a diff when single line arguments are mismatched" do
      with_unfulfilled_double do |d|
        expect(d).to receive(:foo).with("some string")
        expect {
          d.foo("this other string")
        }.to fail_with(a_string_excluding("Diff:"))
      end
    end

    it "does not print a diff when differ returns a string of only whitespace" do
      differ = instance_double(RSpec::Support::Differ, :diff => "  \n  \t ")
      allow(RSpec::Support::Differ).to receive_messages(:new => differ)

      with_unfulfilled_double do |d|
        expect(d).to receive(:foo).with("some string\nline2")
        expect {
          d.foo("this other string")
        }.to fail_with(a_string_excluding("Diff:"))
      end
    end

    it "does not print a diff when differ returns a string of only whitespace when colour is enabled" do
      allow(RSpec::Mocks.configuration).to receive(:color?) { true }
      differ = instance_double(RSpec::Support::Differ, :diff => "\e[0m\n  \t\e[0m")
      allow(RSpec::Support::Differ).to receive_messages(:new => differ)

      with_unfulfilled_double do |d|
        expect(d).to receive(:foo).with("some string\nline2")
        expect {
          d.foo("this other string")
        }.to fail_with(a_string_excluding("Diff:"))
      end
    end

    it "prints a diff of the strings for individual mismatched multi-line string arguments" do
      with_unfulfilled_double do |d|
        expect(d).to receive(:foo).with("some string\nline2")
        expect {
          d.foo("this other string")
        }.to fail_with("#<Double \"double\"> received :foo with unexpected arguments\n" \
          "  expected: (\"some string\\nline2\")\n       got: (\"this other string\")\n" \
          "Diff:\n@@ -1,3 +1,2 @@\n-some string\n-line2\n+this other string\n")
      end
    end

    it "prints a diff of the args lists for multiple mismatched string arguments" do
      with_unfulfilled_double do |d|
        expect(d).to receive(:foo).with("some string\nline2", "some other string")
        expect {
          d.foo("this other string")
        }.to fail_with("#<Double \"double\"> received :foo with unexpected arguments\n" \
          "  expected: (\"some string\\nline2\", \"some other string\")\n" \
          "       got: (\"this other string\")\nDiff:\n@@ -1,3 +1,2 @@\n-some string\\nline2\n-some other string\n+this other string\n")
      end
    end

    it "does not print a diff when multiple single-line string arguments are mismatched" do
      with_unfulfilled_double do |d|
        expect(d).to receive(:foo).with("some string", "some other string")
        expect {
          d.foo("this other string", "a fourth string")
        }.to fail_with(a_string_excluding("Diff:"))
      end
    end

    let(:expected_hash) { {:baz => :quz, :foo => :bar } }

    let(:actual_hash) { {:bad => :hash} }

    it "prints a diff with hash args" do
      with_unfulfilled_double do |d|
        expect(d).to receive(:foo).with(expected_hash)
        expect {
          d.foo({:bad => :hash})
        }.to fail_with(/\A#<Double "double"> received :foo with unexpected arguments\n  expected: \(#{hash_regex_inspect expected_hash}\)\n       got: \(#{hash_regex_inspect actual_hash}\)\nDiff:\n@@ #{Regexp.escape one_line_header} @@\n\-\[#{hash_regex_inspect expected_hash}\]\n\+\[#{hash_regex_inspect actual_hash}\]\n\z/)
      end
    end

    it "prints a diff with an expected hash arg and a non-hash actual arg" do
      with_unfulfilled_double do |d|
        expect(d).to receive(:foo).with(expected_hash)
        expect {
          d.foo(Object.new)
        }.to fail_with(/-\[#{hash_regex_inspect expected_hash}\].*\+\[#<Object.*>\]/m)
      end
    end

    context 'with keyword arguments on normal doubles' do
      if RSpec::Support::RubyFeatures.distincts_kw_args_from_positional_hash?
        eval <<-'RUBY', nil, __FILE__, __LINE__ + 1
          it "prints a diff when keyword argument were expected but got an option hash (using splat)" do
            with_unfulfilled_double do |d|
              expect(d).to receive(:foo).with(**expected_hash)
              expect {
                d.foo(expected_hash)
              }.to fail_with(
                "#<Double \"double\"> received :foo with unexpected arguments\n" \
                "  expected: ({:baz=>:quz, :foo=>:bar}) (keyword arguments)\n" \
                "       got: ({:baz=>:quz, :foo=>:bar}) (options hash)"
              )
            end
          end
        RUBY

        eval <<-'RUBY', nil, __FILE__, __LINE__ + 1
          it "prints a diff when keyword argument were expected but got an option hash (literal)" do
            with_unfulfilled_double do |d|
              expect(d).to receive(:foo).with(:positional, keyword: 1)
              expect {
                options = { keyword: 1 }
                d.foo(:positional, options)
              }.to fail_with(
                "#<Double \"double\"> received :foo with unexpected arguments\n" \
                "  expected: (:positional, {:keyword=>1}) (keyword arguments)\n" \
                "       got: (:positional, {:keyword=>1}) (options hash)"
              )
            end
          end
        RUBY

        eval <<-'RUBY', nil, __FILE__, __LINE__ + 1
          it "prints a diff when the positional argument doesnt match" do
            with_unfulfilled_double do |d|
              input = Class.new

              expected_input = input.new()
              actual_input = input.new()

              expect(d).to receive(:foo).with(expected_input, one: 1)

              expect {
                options = { one: 1 }
                d.foo(actual_input, options)
              }.to fail_with(
                "#<Double \"double\"> received :foo with unexpected arguments\n" \
                "  expected: (#{expected_input.inspect}, {:one=>1}) (keyword arguments)\n" \
                "       got: (#{actual_input.inspect}, {:one=>1}) (options hash)\n" \
                "Diff:\n" \
                "@@ -1 +1 @@\n" \
                "-[#{expected_input.inspect}, {:one=>1}]\n" \
                "+[#{actual_input.inspect}, {:one=>1}]\n"
              )
            end
          end
        RUBY
      end
    end

    context 'with keyword arguments on partial doubles' do
      include_context "with isolated configuration"

      let(:d) { Class.new { def foo(a, b); end }.new }

      before(:example) do
        RSpec::Mocks.configuration.verify_partial_doubles = true
        allow(RSpec.configuration).to receive(:color_enabled?) { false }
      end

      after(:example) { reset d }

      if RSpec::Support::RubyFeatures.distincts_kw_args_from_positional_hash?
        eval <<-'RUBY', nil, __FILE__, __LINE__ + 1
          it "prints a diff when keyword argument were expected but got an option hash (using splat)" do
            expect(d).to receive(:foo).with(:positional, **expected_hash)
            expect {
              d.foo(:positional, expected_hash)
            }.to fail_with(
              "#{d.inspect} received :foo with unexpected arguments\n" \
              "  expected: (:positional, {:baz=>:quz, :foo=>:bar}) (keyword arguments)\n" \
              "       got: (:positional, {:baz=>:quz, :foo=>:bar}) (options hash)"
            )
          end
        RUBY

        eval <<-'RUBY', nil, __FILE__, __LINE__ + 1
          it "prints a diff when keyword argument were expected but got an option hash (literal)" do
            expect(d).to receive(:foo).with(:positional, keyword: 1)
            expect {
              options = { keyword: 1 }
              d.foo(:positional, options)
            }.to fail_with(
              "#{d.inspect} received :foo with unexpected arguments\n" \
              "  expected: (:positional, {:keyword=>1}) (keyword arguments)\n" \
              "       got: (:positional, {:keyword=>1}) (options hash)"
            )
          end
        RUBY

        eval <<-'RUBY', nil, __FILE__, __LINE__ + 1
          it "prints a diff when the positional argument doesnt match" do
            input = Class.new

            expected_input = input.new()
            actual_input = input.new()

            expect(d).to receive(:foo).with(expected_input, one: 1)

            expect {
              options = { one: 1 }
              d.foo(actual_input, options)
            }.to fail_with(
              "#{d.inspect} received :foo with unexpected arguments\n" \
              "  expected: (#{expected_input.inspect}, {:one=>1}) (keyword arguments)\n" \
              "       got: (#{actual_input.inspect}, {:one=>1}) (options hash)\n" \
              "Diff:\n" \
              "@@ -1 +1 @@\n" \
              "-[#{expected_input.inspect}, {:one=>1}]\n" \
              "+[#{actual_input.inspect}, {:one=>1}]\n"
            )
          end
        RUBY
      end
    end

    if RUBY_VERSION.to_f < 1.9
      # Ruby 1.8 hashes are not ordered, but `#inspect` on a particular unchanged
      # hash instance should return consistent output. However, on Travis that does
      # not always seem to be true and we have no idea why. Somehow, the travis build
      # has occasionally failed due to the output ordering varying between `inspect`
      # calls to the same hash. This regex allows us to work around that.
      def hash_regex_inspect(hash)
        "\\{(#{hash.map { |key, value| "#{key.inspect}=>#{value.inspect}.*" }.join "|"}){#{hash.size}}\\}"
      end
    else
      def hash_regex_inspect(hash)
        Regexp.escape(hash.inspect)
      end
    end

    it "prints a diff with array args" do
      with_unfulfilled_double do |d|
        expect(d).to receive(:foo).with([:a, :b, :c])
        expect {
          d.foo([])
        }.to fail_with("#<Double \"double\"> received :foo with unexpected arguments\n  expected: ([:a, :b, :c])\n       got: ([])\nDiff:\n@@ #{one_line_header} @@\n-[[:a, :b, :c]]\n+[[]]\n")
      end
    end

    context "that defines #description" do
      it "does not use the object's description for a non-matcher object that implements #description" do
        with_unfulfilled_double do |d|

          collab = double(:collab, :description => "This string")
          collab_inspect = collab.inspect

          expect(d).to receive(:foo).with(collab)
          expect {
            d.foo([])
          }.to fail_with("#<Double \"double\"> received :foo with unexpected arguments\n" \
            "  expected: (#{collab_inspect})\n" \
            "       got: ([])\nDiff:\n@@ #{one_line_header} @@\n-[#{collab_inspect}]\n+[[]]\n")
        end
      end
    end
  end

  context "with a matcher object" do
    context "that defines #description" do
      it "uses the object's description" do
        with_unfulfilled_double do |d|

          collab = fake_matcher(Object.new)
          collab_description = collab.description

          expect(d).to receive(:foo).with(collab)
          expect {
            d.foo([:a, :b])
          }.to fail_with("#<Double \"double\"> received :foo with unexpected arguments\n" \
            "  expected: (#{collab_description})\n" \
            "       got: ([:a, :b])\nDiff:\n@@ #{one_line_header} @@\n-[\"#{collab_description}\"]\n+[[:a, :b]]\n")
        end
      end
    end

    context "that does not define #description" do
      it "for a matcher object that does not implement #description" do
        with_unfulfilled_double do |d|
          collab = Class.new do
            def self.name
              "RSpec::Mocks::ArgumentMatchers::"
            end

            def inspect
              "#<MyCollab>"
            end
          end.new

          expect(RSpec::Support.is_a_matcher?(collab)).to be true

          collab_inspect = collab.inspect
          collab_pp = PP.pp(collab, "".dup).strip

          expect(d).to receive(:foo).with(collab)
          expect {
            d.foo([:a, :b])
          }.to fail_with("#<Double \"double\"> received :foo with unexpected arguments\n" \
            "  expected: (#{collab_inspect})\n" \
            "       got: ([:a, :b])\nDiff:\n@@ #{one_line_header} @@\n-[#{collab_pp}]\n+[[:a, :b]]\n")
        end
      end
    end
  end
end
