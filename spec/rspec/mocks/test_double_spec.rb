module RSpec
  module Mocks
    describe TestDouble do
      describe "#freeze" do
        subject { double }

        it "gives a warning" do
          expect(RSpec).to receive(:warn_with).with(/freeze a test double/)
          subject.freeze
        end

        it "gives the correct call site for the warning" do
          expect_warning_with_call_site(__FILE__, __LINE__+1)
          subject.freeze
        end

        it "doesn't freeze the object" do
          allow(RSpec).to receive(:warn_with).with(/freeze a test double/)
          double.freeze
          allow(subject).to receive(:hi)

          expect {
            subject.hi
          }.not_to raise_error
        end
      end

      [[:should, :expect], [:expect], [:should]].each do |syntax|
        context "with syntax #{syntax.inspect}" do
          include_context "with syntax", syntax

          it 'stubs the methods passed in the stubs hash' do
            dbl = double("MyDouble", :a => 5, :b => 10)

            expect(dbl.a).to eq(5)
            expect(dbl.b).to eq(10)
          end
        end
      end
    end
  end
end
