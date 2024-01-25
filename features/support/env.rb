require 'aruba/cucumber'
require 'rspec/expectations'

Aruba.configure do |config|
  if RUBY_PLATFORM =~ /java/ || defined?(Rubinius) || (defined?(RUBY_ENGINE) && RUBY_ENGINE == 'truffleruby')
    config.exit_timeout = 60
  else
    config.exit_timeout = 5
  end
end

Before do
  if RUBY_PLATFORM == 'java'
    # disable JIT since these processes are so short lived
    set_environment_variable('JRUBY_OPTS', "-X-C #{ENV['JRUBY_OPTS']}")
  end

  if defined?(Rubinius)
    # disable JIT since these processes are so short lived
    set_environment_variable('RBXOPT', "-Xint=true #{ENV['RBXOPT']}")
  end
end

Before('@ripper') do |scenario|
  unless RSpec::Support::RubyFeatures.ripper_supported?
    warn "Skipping scenario due to lack of Ripper support"
    if Cucumber::VERSION.to_f >= 3.0
      skip_this_scenario
    else
      scenario.skip_invoke!
    end
  end
end

Before('@kw-arguments') do |scenario|
  unless RSpec::Support::RubyFeatures.kw_args_supported?
    warn "Skipping scenario due to lack of keyword argument support"
    if Cucumber::VERSION.to_f >= 3.0
      skip_this_scenario
    else
      scenario.skip_invoke!
    end
  end
end

Before('@distincts_kw_args_from_positional_hash') do |scenario|
  unless RSpec::Support::RubyFeatures. distincts_kw_args_from_positional_hash?
    warn "Skipping scenario due to not applicable to this ruby"
    if Cucumber::VERSION.to_f >= 3.0
      skip_this_scenario
    else
      scenario.skip_invoke!
    end
  end
end
