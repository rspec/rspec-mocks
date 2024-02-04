require 'memory_profiler'

n = 10_000

def find_with_proc(argument)
  lambda do |lambda_arg|
    lambda_arg == argument
  end
end

def find(argument, lambda_arg)
  lambda_arg == argument
end

puts "#{n} items - ruby #{RUBY_VERSION}"

puts
puts "find_with_proc"

MemoryProfiler.report do
  100.times do
    1.upto(n).select(&find_with_proc(50))
  end
end.pretty_print

puts
puts "find"

MemoryProfiler.report do
  100.times do
    1.upto(n).select { |i| find(50, i) }
  end
end.pretty_print

# $ ruby benchmarks/allocations/2_lambda_ref_find.rb
# 10000 items - ruby 3.2.2
#
# find_with_proc
# Total allocated: 29600 bytes (400 objects)
# Total retained:  0 bytes (0 objects)
#
# allocated memory by gem
# -----------------------------------
#      29600  other
#
# allocated memory by file
# -----------------------------------
#      29600  benchmarks/allocations/2_lambda_ref_find.rb
#
# allocated memory by location
# -----------------------------------
#      21600  benchmarks/allocations/2_lambda_ref_find.rb:22
#       8000  benchmarks/allocations/2_lambda_ref_find.rb:6
#
# allocated memory by class
# -----------------------------------
#      13600  Enumerator
#       8000  Array
#       8000  Proc
#
# allocated objects by gem
# -----------------------------------
#        400  other
#
# allocated objects by file
# -----------------------------------
#        400  benchmarks/allocations/2_lambda_ref_find.rb
#
# allocated objects by location
# -----------------------------------
#        300  benchmarks/allocations/2_lambda_ref_find.rb:22
#        100  benchmarks/allocations/2_lambda_ref_find.rb:6
#
# allocated objects by class
# -----------------------------------
#        200  Array
#        100  Enumerator
#        100  Proc
#
#
# find
# Total allocated: 21600 bytes (300 objects)
# Total retained:  0 bytes (0 objects)
#
# allocated memory by gem
# -----------------------------------
#      21600  other
#
# allocated memory by file
# -----------------------------------
#      21600  benchmarks/allocations/2_lambda_ref_find.rb
#
# allocated memory by location
# -----------------------------------
#      21600  benchmarks/allocations/2_lambda_ref_find.rb:31
#
# allocated memory by class
# -----------------------------------
#      13600  Enumerator
#       8000  Array
#
# allocated objects by gem
# -----------------------------------
#        300  other
#
# allocated objects by file
# -----------------------------------
#        300  benchmarks/allocations/2_lambda_ref_find.rb
#
# allocated objects by location
# -----------------------------------
#        300  benchmarks/allocations/2_lambda_ref_find.rb:31
#
# allocated objects by class
# -----------------------------------
#        200  Array
#        100  Enumerator
