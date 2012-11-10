source "http://rubygems.org"

gemspec

%w[rspec rspec-core rspec-expectations rspec-mocks].each do |lib|
  library_path = File.expand_path("../../#{lib}", __FILE__)
  if File.exist?(library_path)
    gem lib, :path => library_path
  else
    gem lib, :git => "git://github.com/rspec/#{lib}.git"
  end
end

### deps for rdoc.info
group :documentation do
  gem 'yard'
  gem 'redcarpet'
  gem 'github-markup'
end

platforms :jruby do
  gem "jruby-openssl"
end

eval File.read('Gemfile-custom') if File.exist?('Gemfile-custom')
