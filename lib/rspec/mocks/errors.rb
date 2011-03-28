module RSpec
  module Mocks
    class MockExpectationError < Exception
    end
    
    class AmbiguousReturnError < StandardError
    end
    
    class InvalidExpectationError < StandardError
    end
  end
end

