module RSpec
  module Mocks
    module AnyInstance
      class StubChain
        InvocationOrder = {
          :with => [:stub],
          :and_return => [:with, :stub],
          :and_raise => [:with, :stub]
        }
        
        def initialize(method_name, *args, &block)
          @messages = []
          record(:stub, [method_name] + args, block)
        end
        
        def with(*args, &block)
          record(:with, args, block)
        end

        def and_return(*args, &block)
          record(:and_return, args, block)
        end
        
        def and_raise(*args, &block)
          record(:and_raise, args, block)
        end

        def record(rspec_method_name, args, block)
          verify_invocation_order(rspec_method_name, args, block)
          @messages << [args.unshift(rspec_method_name), block]
          self
        end
        
        def verify_invocation_order(rspec_method_name, args, block)
          if rspec_method_name != :stub && !InvocationOrder[rspec_method_name].include?(last_message)
            raise(NoMethodError, "Undefined method #{rspec_method_name}")
          end
        end
        
        def last_message
          @messages.last.first.first unless @messages.empty?
        end
        
        def playback!(target)
          @messages.inject(target) do |target, message|
            target.__send__(*message.first, &message.last)
          end
        end
      end
      
      class Recorder
        def initialize(klass)
          @stubs = {}
          @klass = klass
        end

        def stub(method_name, *args, &block)
          observe!(method_name)
          @stubs[method_name.to_sym] = StubChain.new(method_name, *args, &block)
        end
        
        def playback!(target, method_name)
          @stubs[method_name].playback!(target)
        end
        
        def observed_methods
          @stubs.keys
        end
        
        def stop_observing_currently_observed_methods!
          observed_methods.each do |method_name|
            stop_observing!(method_name)
          end
        end

        def stop_observing!(method_name)
          alias_method_name = "__#{method_name}_without_any_instance__"
          if @klass.respond_to?(alias_method_name)
            restore_original_method!(alias_method_name)
          else
            remove_dummy_method!(method_name)
          end
        end

        def restore_original_method!(alias_method_name)
          @klass.class_eval do
            alias_method  method_name, alias_method_name
            remove_method alias_method_name
          end
        end
        
        def remove_dummy_method!(method_name)
          @klass.class_eval do
            remove_method method_name
          end
        end
        
        def observe!(method_name)
          @klass.class_eval do
            if respond_to?(method_name)
              alias_method "__#{method_name}_without_any_instance__", method_name
            end
            define_method(method_name) do |*args, &blk|
              self.class.__recorder.playback!(self, method_name)
              self.send(method_name, *args, &blk)
            end
          end
        end
      end

      def any_instance
        RSpec::Mocks::space.add(self) if RSpec::Mocks::space
        __recorder
      end

      def rspec_reset
        __recorder.stop_observing_currently_observed_methods!
        @__recorder = nil
        response = super
        response
      end

      def reset?
        !@__recorder && super
      end

      def __recorder
        @__recorder ||= AnyInstance::Recorder.new(self)
      end
    end
  end
end