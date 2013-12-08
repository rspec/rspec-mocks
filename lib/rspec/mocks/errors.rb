module RSpec
  module Mocks
    # @private
    class MockExpectationError < Exception
    end

    # @private
    class AmbiguousReturnError < StandardError
    end

    # @private
    class UnrestorableStubError < StandardError
    end
  end
end

