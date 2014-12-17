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

# $ export OLD_REV=8018b83f33793649d3361ea0d64ac4b29fe79d17
# $ git checkout $OLD_REV
# $ ruby benchmarks/mock_space_reverse_each.rb
#
# 1000 times - ruby 2.1.5
#
#            user       system     total    real
# 1 times    0.070000   0.000000   0.070000 (0.068984)
# 10 times   0.630000   0.000000   0.630000 (0.633640)
# 100 times  6.160000   0.050000   6.210000 (6.208566)
#
# $ export NEW_REV=16cd1fecfaf03723e1e0c8e186179c1e3d54a35c
# $ git checkout $NEW_REV
# $ ruby benchmarks/mock_space_reverse_each.rb
#
# 1000 times - ruby 2.1.5
#
#            user       system     total    real
# 1 times    0.070000   0.000000   0.070000 (0.073021)
# 10 times   0.690000   0.010000   0.700000 (0.698443)
# 100 times  7.010000   0.060000   7.070000 (7.105332)
