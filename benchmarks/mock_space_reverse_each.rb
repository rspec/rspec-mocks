$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))

require 'benchmark'
require 'rspec/mocks'

n = 1000

puts "#{n} times - ruby #{RUBY_VERSION}"
puts

Benchmark.bm do |bm|
  RSpec::Mocks.setup
  RSpec::Mocks.configuration.syntax = :should

  object = Object.new

  [1,10,100].each do |m|
    bm.report("#{m} times") do
      n.times do
        m.times do |i|
          object.stub("method_#{i}")
        end
        RSpec::Mocks.space.reset_all
      end
    end
  end
end
