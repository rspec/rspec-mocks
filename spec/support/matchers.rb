module RSpec
  module Matchers
    def fail
      raise_error(RSpec::Mocks::MockExpectationError)
    end

    def fail_with(*args)
      raise_error(RSpec::Mocks::MockExpectationError, *args)
    end

    def fail_including(*snippets)
      raise_error(
        RSpec::Mocks::MockExpectationError,
        a_string_including(*snippets)
      )
    end
  end
end
