source "https://rubygems.org"

gemspec

branch = File.read(File.expand_path("../maintenance-branch", __FILE__)).chomp
%w[rspec rspec-core rspec-expectations].each do |lib|
  library_path = File.expand_path("../../#{lib}", __FILE__)
  if File.exist?(library_path) && !ENV['USE_GIT_REPOS']
    gem lib, :path => library_path
  else
    gem lib, :git => "https://github.com/rspec/#{lib}.git", :branch => branch
  end
end

gem 'rspec-support', github: 'rspec/rspec-support', branch: 'add-proc-kwargs-detection-support'

if ENV['DIFF_LCS_VERSION']
  gem 'diff-lcs', ENV['DIFF_LCS_VERSION']
else
  gem 'diff-lcs', '~> 1.4', '>= 1.4.3'
end

gem 'ffi', '~> 1.12.0'

gem 'yard', '~> 0.9.24', :require => false

# No need to run rubocop on earlier versions
if RUBY_VERSION >= '2.4' && RUBY_ENGINE == 'ruby'
  gem 'rubocop', "~> 0.52.1"
end

# Version 5.12 of minitest requires Ruby 2.4
if RUBY_VERSION < '2.4.0'
  gem 'minitest', '< 5.12.0'
end

### deps for rdoc.info
group :documentation do
  gem 'redcarpet', :platform => :mri
  gem 'github-markup', :platform => :mri
end

gem 'simplecov', '~> 0.8'

gem "jruby-openssl", platforms: [:jruby]

eval_gemfile 'Gemfile-custom' if File.exist?('Gemfile-custom')
