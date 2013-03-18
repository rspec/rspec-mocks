require 'spec_helper'

module RSpec
  module Mocks
    describe Methods, :if => (Method.method_defined?(:owner)) do
      def methods_added_to_all_objects
        some_object = Object.new
        (some_object.methods + some_object.private_methods).select do |method|
          some_object.method(method).owner == RSpec::Mocks::Methods
        end.map(&:to_sym)
      end

      it 'limits the number of methods that get added to all objects' do
        # If really necessary, you can add to this list, but long term,
        # we are hoping to cut down on the number of methods added to all objects
        expect(methods_added_to_all_objects).to match_array([
          :__mock_proxy, :__remove_mock_proxy, :as_null_object,
          :format_chain, :null_object?, :received_message?,
          :rspec_reset, :rspec_verify, :should_not_receive,
          :should_receive, :stub, :stub!,
          :stub_chain, :unstub, :unstub!
        ])
      end
    end
  end
end

