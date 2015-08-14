require 'rspec/mocks'

Minitest::Expectation.class_eval do
  def to(*args, &block)
    ::RSpec::Mocks::ExpectationTarget.new(target).to(*args, &block)
  end

  def not_to(*args, &block)
    ::RSpec::Mocks::ExpectationTarget.new(target).not_to(*args, &block)
  end

  def to_not(*args, &block)
    ::RSpec::Mocks::ExpectationTarget.new(target).to_not(*args, &block)
  end
end
