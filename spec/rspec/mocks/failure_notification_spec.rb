RSpec.describe "Failure notification" do
  def capture_errors(&block)
    errors = []
    RSpec::Support.with_failure_notifier(lambda { |e| errors << e }, &block)
    errors
  end

  it "uses the rspec-support notifier to support `aggregate_failures`" do
    dbl = double("Foo")

    expect(capture_errors { dbl.some_unallowed_method }).to match [an_object_having_attributes(
      :message => a_string_including(dbl.inspect, "some_unallowed_method")
    )]
  end

  it "includes the line of future expectation in the notification for an unreceived message" do
    dbl = double("Foo")
    expect(dbl).to receive(:wont_happen); expected_from_line = __LINE__

    error = capture_errors { verify dbl }.first
    expect(error.backtrace.first).to match(/#{File.basename(__FILE__)}:#{expected_from_line}/)
  end
end
