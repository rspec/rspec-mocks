module RSpec
  module Matchers
    def fail
      raise_error(RSpec::Mocks::MockExpectationError)
    end

    def fail_with(message=nil)
      raise_error(RSpec::Mocks::MockExpectationError, message)
    end

    def fail_matching(message)
      raise_error(RSpec::Mocks::MockExpectationError, (String === message ? /#{Regexp.escape(message)}/ : message))
    end
  end
end
