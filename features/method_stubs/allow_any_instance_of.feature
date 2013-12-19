Feature: stub on any instance of a class

  Use `allow_any_instance_of` on a class to tell any instance of that class to
  return a value (or values) in response to a given message.  If no instance
  receives the message, nothing happens.

  Messages can be stubbed on any class, including those in Ruby's core library.

  Note: You can use `allow_any_instance_of` when you don't have a reference
  to the object that receives a message in your test. For more information,
  see the message_expectations/allow_any_instance_of feature.

  Scenario: Stubbing any instance of an object with a single return value
    Given a file named "example_spec.rb" with:
      """ruby
      describe "stubbing any instance" do
        it "returns the specified value on any instance of the class" do
          allow_any_instance_of(Object).to receive(:foo).and_return(:return_value)

          o = Object.new
          expect(o.foo).to eq(:return_value)
        end
      end
      """
    When I run `rspec example_spec.rb`
    Then the examples should all pass

  Scenario: any_instance stub with a hash
    Given a file named "example_spec.rb" with:
      """ruby
      describe "any_instance.stub" do
        context "with a hash" do
          it "returns the hash values on any instance of the class" do
            allow_any_instance_of(Object).to receive_messages(:foo => 'foo', :bar => 'bar')

            o = Object.new
            expect(o.foo).to eq('foo')
            expect(o.bar).to eq('bar')
          end
        end
      end
      """
    When I run `rspec example_spec.rb`
    Then the examples should all pass

  Scenario: Stubbing any instance of an object with specific arguments matchers
    Given a file named "example_spec.rb" with:
      """ruby
      describe "stubbing any instance" do
        context "with arguments" do
          it "returns the stubbed value when arguments match" do
            allow_any_instance_of(Object).to receive(:foo).with(:param_one, :param_two).and_return(:result_one)
            allow_any_instance_of(Object).to receive(:foo).with(:param_three, :param_four).and_return(:result_two)

            o = Object.new
            expect(o.foo(:param_one, :param_two)).to eq(:result_one)
            expect(o.foo(:param_three, :param_four)).to eq(:result_two)
          end
        end
      end
      """
    When I run `rspec example_spec.rb`
    Then the examples should all pass

  Scenario: any_instance unstub
    Given a file named "example_spec.rb" with:
      """ruby
      describe "any_instance.unstub" do
        it "unstubs a stubbed method" do
          class Object
            def foo
              :foo
            end
          end

          Object.any_instance.stub(:foo)
          Object.any_instance.unstub(:foo)

          expect(Object.new.foo).to eq(:foo)
        end
      end
      """
    When I run `rspec example_spec.rb`
    Then the examples should all pass

  Scenario: any_instance unstub
    Given a file named "example_spec.rb" with:
      """ruby
      describe "any_instance.unstub" do
        context "with both an expectation and a stub already set" do
          it "only removes the stub" do
            class Object
              def foo
                :foo
              end
            end
            expect_any_instance_of(Object).to receive(:foo).and_return(:bar)
            Object.any_instance.stub(:foo)
            Object.any_instance.unstub(:foo)

            expect(Object.new.foo).to eq(:bar)
          end
        end
      end
      """
    When I run `rspec example_spec.rb`
    Then the examples should all pass

  Scenario: stub a chain of methods an any instance
    Given a file named "stub_chain_spec.rb" with:
      """ruby
      describe "stubbing a chain of methods" do
        context "given symbols representing methods" do
          it "returns the correct value" do
            allow_any_instance_of(Object).to receive_message_chain(:one, :two, :three).and_return(:four)
            expect(Object.new.one.two.three).to eq(:four)
          end
        end

        context "given a hash at the end" do
          it "returns the correct value" do
            allow_any_instance_of(Object).to receive_message_chain(:one, :two, :three=> :four)
            expect(Object.new.one.two.three).to eq(:four)
          end
        end

        context "given a string of methods separated by dots" do
          it "returns the correct value" do
            allow_any_instance_of(Object).to receive_message_chain("one.two.three").and_return(:four)
            expect(Object.new.one.two.three).to eq(:four)
          end
        end
      end
      """
    When I run `rspec stub_chain_spec.rb`
    Then the examples should all pass
