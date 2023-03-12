begin
  require 'aruba/rspec'

  Aruba.configure do |config|
    if RUBY_PLATFORM =~ /java/ || defined?(Rubinius) || (defined?(RUBY_ENGINE) && RUBY_ENGINE == 'truffleruby')
      config.exit_timeout = 60
    else
      config.exit_timeout = 5
    end
  end
rescue NameError => e
  # This silences a name error on unsupported version of JRuby
  raise e unless RSpec::Support::Ruby.jruby? && JRUBY_VERSION =~ /9\.1\.17\.0/
rescue LoadError => e
  # This silences a load error on unsupported version of JRuby
  raise e unless RSpec::Support::Ruby.jruby? && JRUBY_VERSION =~ /9\.1\.17\.0/
end
