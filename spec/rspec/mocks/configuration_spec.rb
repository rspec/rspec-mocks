module RSpec
  module Mocks
    RSpec.describe Configuration do
      let(:config) { Configuration.new }

      describe "#when_declaring_verifying_double" do
        include_context 'with isolated configuration'

        it "captures the supplied blocks" do
          block = proc { |ref| ref }
          block2 = proc { |ref| ref }
          RSpec.configuration.mock_with :rspec do |config|
            config.before_verifying_doubles(&block)
            config.when_declaring_verifying_double(&block2)
            expect(config.verifying_double_callbacks).to eq [block, block2]
          end
        end
      end
    end
  end
end
