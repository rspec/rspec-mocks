module RSpec
  module Mocks
    module AnyInstance
      # Given a class `TheClass`, `TheClass.any_instance` returns a `Recorder`,
      # which records stubs and message expectations for later playback on
      # instances of `TheClass`.
      #
      # Further constraints are stored in instances of [Chain](Chain).
      #
      # @see AnyInstance
      # @see Chain
      class Recorder
        # @private
        attr_reader :message_chains, :stubs, :klass

        def initialize(klass)
          @message_chains = MessageChains.new
          @stubs = Hash.new { |hash,key| hash[key] = [] }
          @observed_methods = []
          @played_methods = {}
          @klass = klass
          @expectation_set = false
        end

        # Initializes the recording a stub to be played back against any
        # instance of this object that invokes the submitted method.
        #
        # @see Methods#stub
        def stub(method_name, &block)
          observe!(method_name)
          message_chains.add(method_name, StubChain.new(self, method_name, &block))
        end

        # Initializes the recording a stub chain to be played back against any
        # instance of this object that invokes the method matching the first
        # argument.
        #
        # @see Methods#stub_chain
        def stub_chain(*method_names_and_optional_return_values, &block)
          normalize_chain(*method_names_and_optional_return_values) do |method_name, args|
            observe!(method_name)
            message_chains.add(method_name, StubChainChain.new(self, *args, &block))
          end
        end

        # @private
        def expect_chain(*method_names_and_optional_return_values, &block)
          @expectation_set = true
          normalize_chain(*method_names_and_optional_return_values) do |method_name, args|
            observe!(method_name)
            message_chains.add(method_name, ExpectChainChain.new(self, *args, &block))
          end
        end

        # Initializes the recording a message expectation to be played back
        # against any instance of this object that invokes the submitted
        # method.
        #
        # @see Methods#should_receive
        def should_receive(method_name, &block)
          @expectation_set = true
          observe!(method_name)
          message_chains.add(method_name, PositiveExpectationChain.new(self, method_name, &block))
        end

        # The opposite of `should_receive`
        #
        # @see Methods#should_not_receive
        def should_not_receive(method_name, &block)
          should_receive(method_name, &block).never
        end

        # Removes any previously recorded stubs, stub_chains or message
        # expectations that use `method_name`.
        #
        # @see Methods#unstub
        def unstub(method_name)
          unless @observed_methods.include?(method_name.to_sym)
            raise RSpec::Mocks::MockExpectationError, "The method `#{method_name}` was not stubbed or was already unstubbed"
          end
          message_chains.remove_stub_chains_for!(method_name)
          stubs[method_name].clear
          stop_observing!(method_name) unless message_chains.has_expectation?(method_name)
        end

        # @api private
        #
        # Used internally to verify that message expectations have been
        # fulfilled.
        def verify
          if @expectation_set && !message_chains.all_expectations_fulfilled?
            raise RSpec::Mocks::MockExpectationError, "Exactly one instance should have received the following message(s) but didn't: #{message_chains.unfulfilled_expectations.sort.join(', ')}"
          end
        end

        # @private
        def stop_all_observation!
          @observed_methods.each {|method_name| restore_method!(method_name)}
        end

        # @private
        def playback!(instance, method_name)
          RSpec::Mocks.space.ensure_registered(instance)
          message_chains.playback!(instance, method_name)
          @played_methods[method_name] = instance
          received_expected_message!(method_name) if message_chains.has_expectation?(method_name)
        end

        # @private
        def instance_that_received(method_name)
          @played_methods[method_name]
        end

        # @private
        def build_alias_method_name(method_name)
          "__#{method_name}_without_any_instance__"
        end

        # @private
        def already_observing?(method_name)
          @observed_methods.include?(method_name) || super_class_observing?(method_name)
        end

      protected

        def stop_observing!(method_name)
          restore_method!(method_name)
          @observed_methods.delete(method_name)
          super_class_observers_for(method_name).each do |ancestor|
            ::RSpec::Mocks.space.
              any_instance_recorder_for(ancestor).stop_observing!(method_name)
          end
        end

      private

        def ancestor_is_an_observer?(method_name)
          lambda do |ancestor|
            unless ancestor == @klass
              ::RSpec::Mocks.space.
                any_instance_recorder_for(ancestor).already_observing?(method_name)
            end
          end
        end

        def super_class_observers_for(method_name)
          @klass.ancestors.select(&ancestor_is_an_observer?(method_name))
        end

        def super_class_observing?(method_name)
          @klass.ancestors.any?(&ancestor_is_an_observer?(method_name))
        end

        def normalize_chain(*args)
          args.shift.to_s.split('.').map {|s| s.to_sym}.reverse.each {|a| args.unshift a}
          yield args.first, args
        end

        def received_expected_message!(method_name)
          message_chains.received_expected_message!(method_name)
          restore_method!(method_name)
          mark_invoked!(method_name)
        end

        def restore_method!(method_name)
          if method_defined_on_klass?(build_alias_method_name(method_name))
            restore_original_method!(method_name)
          else
            remove_dummy_method!(method_name)
          end
        end

        def restore_original_method!(method_name)
          if @klass.instance_method(method_name).owner == @klass
            alias_method_name = build_alias_method_name(method_name)
            definition_target.class_exec do
              remove_method method_name
              alias_method  method_name, alias_method_name
              remove_method alias_method_name
            end
          end
        end

        def remove_dummy_method!(method_name)
          definition_target.class_exec do
            remove_method method_name if method_defined?(method_name)
          end
        end

        def backup_method!(method_name)
          alias_method_name = build_alias_method_name(method_name)
          definition_target.class_exec do
            alias_method alias_method_name, method_name
          end if public_protected_or_private_method_defined?(method_name)
        end

        def public_protected_or_private_method_defined?(method_name)
          MethodReference.method_defined_at_any_visibility?(definition_target, method_name)
        end

        def method_defined_on_klass?(method_name)
          MethodReference.method_defined_at_any_visibility?(@klass, method_name)
        end

        def observe!(method_name)
          if RSpec::Mocks.configuration.verify_partial_doubles?
            # TODO: test/fix this with prepended module.
            unless public_protected_or_private_method_defined?(method_name)
              raise MockExpectationError,
                "#{@klass} does not implement ##{method_name}"
            end
          end

          stop_observing!(method_name) if already_observing?(method_name)
          @observed_methods << method_name
          backup_method!(method_name)
          recorder = self
          definition_target.__send__(:define_method, method_name) do |*args, &blk|
            recorder.playback!(self, method_name)
            self.__send__(method_name, *args, &blk)
          end
        end

        def mark_invoked!(method_name)
          backup_method!(method_name)
          recorder = self
          definition_target.__send__(:define_method, method_name) do |*args, &blk|
            invoked_instance = recorder.instance_that_received(method_name)
            inspect = "#<#{self.class}:#{object_id} #{instance_variables.map { |name| "#{name}=#{instance_variable_get name}" }.join(', ')}>"
            raise RSpec::Mocks::MockExpectationError, "The message '#{method_name}' was received by #{inspect} but has already been received by #{invoked_instance}"
          end
        end

        if Support::RubyFeatures.module_prepends_supported?
          RSpecPrependedModule = Class.new(Module)

          def definition_target
            @definition_target ||= if klass_has_prepended_module?
              RSpecPrependedModule.new.tap do |mod|
                @klass.prepend mod
              end
            else
              @klass
            end
          end

          def klass_has_prepended_module?
            true # hardcoded for now to force all `any_instance` uses to run with the prepended module code path to see what breaks
            # @klass.ancestors.take_while { |mod| !(Class === mod) }.any?
          end
        else
          def definition_target
            @klass
          end
        end
      end
    end
  end
end
