require File.expand_path('../../support/aruba', __FILE__)

RSpec.describe "Supporting Rails monkey patches", :type => :aruba do
  before do
    if RSpec::Support::OS.windows? && RUBY_VERSION.to_f < 2.4
      skip "Aruba on windows is broken on Ruby 2.3 and below"
    end
  end

  it "works when Rails has monkey patched #with" do
    write_file(
      "spec/with_monkey_patch_spec.rb",
      """
      class Object
        # Rails monkey patches in **kwargs but this is a good analogy
        def with
        end
      end

      RSpec.describe do
        specify do
          mock = instance_double(\"Hash\")
          allow(mock).to receive(:key?).with(:x) { 1 }

          expect(mock.key?(:x)).to eq 1
        end
      end
      """
    )

    run_command("bundle exec rspec spec/with_monkey_patch_spec.rb")

    expect(last_command_started).to have_output(/0 failures/)
    expect(last_command_started).to have_exit_status(0)
  end

  it "works mocking any instance when Rails has monkey patched #with" do
    write_file(
      "spec/with_monkey_patch_spec.rb",
      """
      class Object
        # Rails monkey patches in **kwargs but this is a good analogy
        def with
        end
      end

      RSpec.describe do
        specify do
          klass = Class.new
          allow_any_instance_of(klass).to receive(:bar).with(:y) { 2 }

          expect(klass.new.bar(:y)).to eq 2
        end
      end
      """
    )

    run_command("bundle exec rspec spec/with_monkey_patch_spec.rb")

    expect(last_command_started).to have_output(/0 failures/)
    expect(last_command_started).to have_exit_status(0)
  end
end
