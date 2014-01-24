source "https://rubygems.org"

gemspec

%w[rspec rspec-core rspec-expectations rspec-support].each do |lib|
  library_path = File.expand_path("../../#{lib}", __FILE__)
  if File.exist?(library_path) && !ENV['USE_GIT_REPOS']
    gem lib, :path => library_path
  else
    gem lib, :git => "git://github.com/rspec/#{lib}.git"
  end
end

### deps for rdoc.info
group :documentation do
  gem 'yard',          '0.8.0', :require => false
  gem 'redcarpet',     '2.1.1' unless RUBY_PLATFORM == 'java'
  gem 'github-markup', '0.7.2'
end

gem 'simplecov', '~> 0.8'

platforms :jruby do
  gem "jruby-openssl"
end

platforms :rbx do
  gem 'rubysl'
  gem 'rubysl-test-unit'
end

eval File.read('Gemfile-custom') if File.exist?('Gemfile-custom')
if ENV["TRAVIS"] == true
  gem "rake",     "~> 10.0.0"
  gem "cucumber", "~> 1.1.9"
  gem "aruba",    "~> 0.5"

  gem "nokogiri", "1.5.2"
  gem "coderay",  "~> 1.0.9"


  gem "mocha",    "~> 0.13.0"
  gem "rr",       "~> 1.0.4"
  gem "flexmock", "~> 0.9.0"
end
