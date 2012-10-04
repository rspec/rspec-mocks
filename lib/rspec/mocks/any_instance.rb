require 'rspec/mocks/any_instance/chain'
require 'rspec/mocks/any_instance/stub_chain'
require 'rspec/mocks/any_instance/stub_chain_chain'
require 'rspec/mocks/any_instance/expectation_chain'
require 'rspec/mocks/any_instance/message_chains'
require 'rspec/mocks/any_instance/recorder'

module RSpec
  module Mocks
    module AnyInstance
      # Used to set stubs and message expectations on any instance of a given
      # class. Returns a [Recorder](Recorder), which records messages like
      # `stub` and `should_receive` for later playback on instances of the
      # class.
      #
      # @example
      #
      #     Car.any_instance.should_receive(:go)
      #     race = Race.new
      #     race.cars << Car.new
      #     race.go # assuming this delegates to all of its cars
      #             # this example would pass
      #
      #     Account.any_instance.stub(:balance) { Money.new(:USD, 25) }
      #     Account.new.balance # => Money.new(:USD, 25))
      #
      # @return [Recorder]
      def any_instance
        RSpec::Mocks::space.add(self)
        modify_dup_to_remove_mock_proxy_when_invoked
        __recorder
      end

      # @private
      def rspec_verify
        __recorder.verify
        super
      ensure
        __recorder.stop_all_observation!
        restore_dup
        @__recorder = nil
      end

      # @private
      def rspec_reset
        restore_dup
        __mock_proxy.reset
      end

      # @private
      def __recorder
        @__recorder ||= AnyInstance::Recorder.new(self)
      end

      private
      def modify_dup_to_remove_mock_proxy_when_invoked
        if method_defined?(:dup) and !method_defined?(:__rspec_original_dup)
          class_eval do
            def __rspec_dup(*arguments, &block)
              __remove_mock_proxy
              __rspec_original_dup(*arguments, &block)
            end

            alias_method  :__rspec_original_dup, :dup
            alias_method  :dup, :__rspec_dup
          end
        end
      end

      def restore_dup
        if method_defined?(:__rspec_original_dup)
          class_eval do
            alias_method  :dup, :__rspec_original_dup
            remove_method :__rspec_original_dup
            remove_method :__rspec_dup
          end
        end
      end
    end
  end
end
