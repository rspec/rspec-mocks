require 'aruba/rspec'

Aruba.configure do |config|
  if RUBY_PLATFORM =~ /java/ || defined?(Rubinius) || (defined?(RUBY_ENGINE) && RUBY_ENGINE == 'truffleruby')
    config.exit_timeout = 60
  else
    config.exit_timeout = 5
  end
end
