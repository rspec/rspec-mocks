require "spec_helper"

describe "the spy family of methods" do
  # These methods are provided in 3.1. We don't want to backport them, but
  # implementing them here is the easiest way to test some backported
  # improvements to the have_received matcher.
  #
  # That is also why these specs are in "spy_spec" rather than elsewhere - for
  # similarity with master branch.
  def object_spy(x)
    object_double(x).as_null_object
  end

  def instance_spy(x)
    class_double(x).as_null_object
  end

  def class_spy(x)
    class_double(x).as_null_object
  end

  shared_examples_for "a verifying spy with a foo method" do
    it 'fails fast when `have_received` is passed an undefined method name' do
      expect {
        expect(subject).to have_received(:bar)
      }.to fail_matching("does not implement")
    end

    it 'fails fast when negative `have_received` is passed an undefined method name' do
      expect {
        expect(subject).to_not have_received(:bar)
      }.to fail_matching("does not implement")
    end
  end

  describe "instance_spy" do
    context "when passing a class object" do
      let(:the_class) do
        Class.new do
          def foo
            3
          end
        end
      end

      subject { instance_spy(the_class) }

      it_behaves_like "a verifying spy with a foo method"
    end

    context "passing a class by string reference" do
      DummyClass = Class.new do
        def foo
          3
        end
      end

      let(:the_class) { "DummyClass" }

      subject { instance_spy(the_class) }

      it_behaves_like "a verifying spy with a foo method"
    end
  end

  describe "object_spy" do
    let(:the_class) do
      Class.new do
        def foo
          3
        end
      end
    end

    let(:the_instance) { the_class.new }

    subject { object_spy(the_instance) }

    it_behaves_like "a verifying spy with a foo method"
  end

  describe "class_spy" do
    let(:the_class) do
      Class.new do
        def self.foo
          3
        end
      end
    end

    subject { class_spy(the_class) }

    it_behaves_like "a verifying spy with a foo method"
  end
end
