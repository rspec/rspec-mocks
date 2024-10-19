Then /^the example(?:s)? should(?: all)? pass$/ do
  step %q(the output should contain "0 failures")
  step %q(the exit status should be 0)
end

Then /^the examples should all fail, producing the following output:$/ do |table|
  step %q(the exit status should be 1)
  examples, failures = all_output.match(/(\d+) examples?, (\d+) failures?/).captures.map(&:to_i)

  expect(examples).to be > 0
  expect(examples).to eq(failures)

  lines = table.raw.flatten.reject(&:empty?)
  expect(all_output).to include(*lines)
end

RSpec::Matchers.define :match_table do |lines|
  match do |all_output|
    lines.all? { |line| all_output.include?(line) }
  end

  diffable
end

Then /^it should fail with the following output(, ignoring hash syntax)?:$/ do |ignore_hash_syntax, table|
  step %q(the exit status should be 1)
  lines = table.raw.flatten.reject(&:empty?)

  if ignore_hash_syntax && RUBY_VERSION.to_f > 3.3
    lines = lines.map { |line| line.gsub(/([^\s])=>/, '\1 => ') }
  end

  expect(all_output).to match_table(lines)
end
