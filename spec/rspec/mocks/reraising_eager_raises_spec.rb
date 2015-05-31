require "spec_helper"

RSpec.describe "Reraising eager raises during the verify step" do
  it "does not reraise when a double receives a message that hasn't been allowed/expected" do
    with_unfulfilled_double do |dbl|
      expect { dbl.foo }.to fail
      expect { verify_all }.not_to raise_error
    end
  end

  it "reraises when a negative expectation receives a call" do
    with_unfulfilled_double do |dbl|
      expect(dbl).not_to receive(:foo)
      expect { dbl.foo }.to fail
      expect { verify_all }.to fail_with(/expected: 0 times with any arguments/)
    end
  end

  it "reraises when an expectation with a count is exceeded" do
    with_unfulfilled_double do |dbl|
      expect(dbl).to receive(:foo).exactly(2).times

      dbl.foo
      dbl.foo

      expect { dbl.foo }.to fail
      expect { verify_all }.to fail_with(/expected: 2 times with any arguments/)
    end
  end

  it "reraises when an expectation is called with the wrong arguments" do
    with_unfulfilled_double do |dbl|
      expect(dbl).to receive(:foo).with(1,2,3)
      expect { dbl.foo(1,2,4) }.to fail
      expect { verify_all }.to fail_with(/expected: 1 time with arguments: \(1, 2, 3\)/)
    end
  end

  it "reraises when an expectation is called out of order",
     :pending => "Says bar was called 0 times when it was, see: http://git.io/pjTq" do
    with_unfulfilled_double do |dbl|
      expect(dbl).to receive(:foo).ordered
      expect(dbl).to receive(:bar).ordered
      expect { dbl.bar }.to fail
      dbl.foo # satisfy the `foo` expectation so that only the bar one fails below
      expect { verify_all }.to fail_with(/received :bar out of order/)
    end
  end
end
