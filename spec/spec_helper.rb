require 'rspec/support/spec'

RSpec::Support::Spec.setup_simplecov do
  minimum_coverage 97
end

require 'yaml'
begin
  require 'psych'
rescue LoadError
end

RSpec::Matchers.define :include_method do |expected|
  match do |actual|
    actual.map { |m| m.to_s }.include?(expected.to_s)
  end
end

module VerifyAndResetHelpers
  def verify(object)
    RSpec::Mocks.proxy_for(object).verify
  end

  def reset(object)
    RSpec::Mocks.proxy_for(object).reset
  end

  def verify_all
    RSpec::Mocks.space.verify_all
  end
end

module VerificationHelpers
  def prevents(&block)
    expect(&block).to \
      raise_error(RSpec::Mocks::MockExpectationError)
  end
end

require 'rspec/support/spec'

RSpec.configure do |config|
  config.mock_with :rspec
  config.color_enabled = true
  config.order = :random
  config.run_all_when_everything_filtered = true
  config.filter_run_including :focus

  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
  end

  # TODO: switch most things to the `expect` syntax (and configure only that here)
  #       but keep a small number of specs that use the old syntax in order to test it
  #       (using the "with syntax" shared context defined below).
  config.mock_with :rspec do |mocks|
    mocks.syntax = [:should, :expect]
  end

  old_verbose = nil
  config.before(:each, :silence_warnings) do
    old_verbose = $VERBOSE
    $VERBOSE = nil
  end

  config.after(:each, :silence_warnings) do
    $VERBOSE = old_verbose
  end

  config.include VerifyAndResetHelpers
  config.include VerificationHelpers
end

shared_context "with syntax" do |syntax|
  orig_syntax = nil

  before(:all) do
    orig_syntax = RSpec::Mocks.configuration.syntax
    RSpec::Mocks.configuration.syntax = syntax
  end

  after(:all) do
    RSpec::Mocks.configuration.syntax = orig_syntax
  end
end


shared_context "with isolated configuration" do
  orig_configuration = nil
  before do
    orig_configuration = RSpec::Mocks.configuration
    RSpec::Mocks.instance_variable_set(:@configuration, RSpec::Mocks::Configuration.new)
  end

  after do
    RSpec::Mocks.instance_variable_set(:@configuration, orig_configuration)
  end
end

shared_context "with the default mocks syntax" do
  orig_syntax = nil

  before(:all) do
    orig_syntax = RSpec::Mocks.configuration.syntax
    RSpec::Mocks.configuration.reset_syntaxes_to_default
  end

  after(:all) do
    RSpec::Mocks.configuration.syntax = orig_syntax
  end

end
