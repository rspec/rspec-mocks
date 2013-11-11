module RSpec
  module Mocks
    class Double
      include TestDouble
    end

    def self.const_missing(name)
      return super unless name == :Mock
      RSpec.deprecate("RSpec::Mocks::Mock", :replacement => "RSpec::Mocks::Double")
      Double
    end
  end
end

