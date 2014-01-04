module RSpec
  module Mocks
    # @private
    class ErrorSpace
      def proxy_for(*args)
        raise_lifecycle_message
      end

      def any_instance_recorder_for(*args)
        raise_lifecycle_message
      end

      def reset_all
      end

      def verify_all
      end

      def registered?(object)
        false
      end

      private

      def raise_lifecycle_message
        raise OutsideOfExampleError, "The use of doubles or partial doubles from rspec-mocks outside of the per-test lifecycle is not supported."
      end
    end

  end
end
