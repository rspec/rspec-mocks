source "https://rubygems.org"

gemspec

branch = File.read(File.expand_path("../maintenance-branch", __FILE__)).chomp
%w[rspec rspec-core rspec-expectations rspec-support].each do |lib|
  library_path = File.expand_path("../../#{lib}", __FILE__)
  if File.exist?(library_path) && !ENV['USE_GIT_REPOS']
    gem lib, :path => library_path
  else
    gem lib, :git => "https://github.com/rspec/#{lib}.git", :branch => branch
  end
end

gem 'yard', '~> 0.9.12', :require => false

if RUBY_VERSION >= '2' && RUBY_VERSION <= '2.1'
  # todo upgrade rubocop and run on a recent version e.g. 2.3 or 2.4
  gem 'rubocop', "~> 0.23.0"
end

if RUBY_VERSION < '2.0.0' && !!(RbConfig::CONFIG['host_os'] =~ /cygwin|mswin|mingw|bccwin|wince|emx/)
  gem 'ffi', '< 1.9.15' # allow ffi to be installed on older rubies on windows
end

### deps for rdoc.info
group :documentation do
  gem 'redcarpet',     '2.1.1' unless RUBY_PLATFORM == 'java'
  gem 'github-markup', '0.7.2'
end

gem 'simplecov', '~> 0.8'

if RUBY_VERSION < '2.0.0' || RUBY_ENGINE == 'java'
  gem 'json', '< 2.0.0' # this is a dependency of simplecov
end

platforms :jruby do
  gem "jruby-openssl"
end

eval File.read('Gemfile-custom') if File.exist?('Gemfile-custom')
