RSpec.shared_context "with compound expectation" do
  let(:dbl) { double }

  before { allow(dbl).to receive_messages(foo: 2, bar: 3) }

  subject(:set_expectation) do
    expect(dbl).to left_expectation
               .public_send compound_method, right_expectation
  end
end

RSpec.shared_examples "supports compound and expectation" do
  let(:compound_method) { :and }

  it "passes if both messages received" do
    dbl.foo
    dbl.bar
    expect { verify }.not_to raise_error
  end

  it "fails if only first message received" do
    dbl.foo
    expect { verify }.to raise_error(/bar\(\*\(any args\)\).*expected: 1 time.*received: 0 times/m)
  end

  it "fails if only second message received" do
    dbl.bar
    expect { verify }.to raise_error(/foo\(\*\(any args\)\).*expected: 1 time.*received: 0 times/m)
  end
end

RSpec.shared_examples "supports compound or expectation" do
  let(:compound_method) { :or }

  it "passes if both messages received" do
    dbl.foo
    dbl.bar
    expect { verify }.not_to raise_error
  end

  it "passes if only first message received" do
    dbl.foo
    expect { verify }.not_to raise_error
  end

  it "passes if only second message received" do
    dbl.bar
    expect { verify }.not_to raise_error
  end
end

RSpec.shared_examples "supports compound expectations" do
  include_context "with compound expectation"

  %i[and or].each do |method|
    context "with `.#{method}`" do
      include_examples "supports compound #{method} expectation"
    end
  end
end
