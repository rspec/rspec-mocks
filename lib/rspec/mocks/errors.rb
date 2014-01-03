module RSpec
  module Mocks
    # @private
    class MockExpectationError < Exception
    end

    # @private
    class ExpiredTestDoubleError < MockExpectationError
    end

    # @private
    class AmbiguousReturnError < StandardError
    end
  end
end

