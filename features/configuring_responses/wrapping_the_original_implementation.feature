Feature: Wrapping the original implementation

  Use `and_wrap_original` to modify a partial double's original response. This can be useful
  when you want to utilise an external object but mutate its response. For example if an
  API returns a large amount of data and for test purposes you'd like to trim it down. You can
  also use it to configure the default response for most arguments, and then override that for
  specific arguments using `with`.

  Note: `and_wrap_original` is only supported on partial doubles, as normal test doubles do
  not have an original implementation.

  Background:
    Given a file named "lib/api.rb" with:
      """ruby
      class API
        def self.solve_for(x)
          (1..x).to_a
        end
      end
      """

  Scenario: `and_wrap_original` wraps the original partial double response
    Given a file named "spec/and_wrap_original_spec.rb" with:
      """ruby
      require 'api'

      RSpec.describe "and_wrap_original" do
        it "responds as it normally would, modified by the block" do
          expect(API).to receive(:solve_for).and_wrap_original { |m, *args| m.call(*args).first(5) }
          expect(API.solve_for(100)).to eq [1,2,3,4,5]
        end
      end
      """
    When I run `rspec spec/and_wrap_original_spec.rb`
    Then the examples should all pass

  Scenario: `and_wrap_original` can configure a default response that can be overridden for specific args
    Given a file named "spec/and_wrap_original_spec.rb" with:
      """ruby
      require 'api'

      RSpec.describe "and_wrap_original" do
        it "can be overridden for specific arguments using #with" do
          allow(API).to receive(:solve_for).and_wrap_original { |m, *args| m.call(*args).first(5) }
          allow(API).to receive(:solve_for).with(2).and_return([3])

          expect(API.solve_for(20)).to eq [1,2,3,4,5]
          expect(API.solve_for(2)).to eq [3]
        end
      end
      """
    When I run `rspec spec/and_wrap_original_spec.rb`
    Then the examples should all pass

  @kw-arguments
  Scenario: `and_wrap_original` can configure a default response that can be overridden for specific keyword arguments
    Given a file named "lib/kw_api.rb" with:
      """ruby
      class API
        def self.solve_for(x: 1, y: 2)
          (x..y).to_a
        end
      end
      """
    Given a file named "spec/and_wrap_original_spec.rb" with:
      """ruby
      require 'kw_api'

      RSpec.describe "and_wrap_original" do
        it "can be overridden for specific arguments using #with" do
          allow(API).to receive(:solve_for).and_wrap_original { |m, **kwargs| m.call(**kwargs).first(5) }
          allow(API).to receive(:solve_for).with(x: 3, y: 4).and_return([3])

          expect(API.solve_for(x: 1, y: 20)).to eq [1,2,3,4,5]
          expect(API.solve_for(y: 20)).to eq [1,2,3,4,5]
          expect(API.solve_for(x: 3, y: 4)).to eq [3]
        end
      end
      """
    When I run `rspec spec/and_wrap_original_spec.rb`
    Then the examples should all pass
