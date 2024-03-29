# This file is designed to prevent the use of certain APIs that
# we don't want used from our cukes, since they function as documentation.

if defined?(Cucumber)
  require 'shellwords'
  tag = !defined?(::RUBY_ENGINE_VERSION) || (::RUBY_ENGINE_VERSION < '2.0.0') ? '~@allow-old-syntax' : 'not @allow-old-syntax'
  Before(tag) do
    set_environment_variable('SPEC_OPTS', "-r#{Shellwords.escape(__FILE__)}")
  end
else
  module DisallowOneLinerShould
    def should(*)
      raise "one-liner should is not allowed"
    end

    def should_not(*)
      raise "one-liner should_not is not allowed"
    end
  end

  RSpec.configure do |rspec|
    rspec.disable_monkey_patching!
    rspec.include DisallowOneLinerShould
  end
end
