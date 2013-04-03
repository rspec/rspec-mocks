require 'spec_helper'

module RSpec
  module Mocks
    describe Methods, :if => (Method.method_defined?(:owner)) do
      def added_methods(klass, owner)
        some_object = klass.new
        (some_object.methods + some_object.private_methods).select do |method|
          some_object.method(method).owner == owner
        end.map(&:to_sym)
      end

      it 'limits the number of methods that get added to all objects' do
        # If really necessary, you can add to this list, but long term,
        # we are hoping to cut down on the number of methods added to all objects
        expect(added_methods(Object, RSpec::Mocks::Methods)).to match_array([
          :as_null_object, :null_object?,
          :received_message?, :should_not_receive, :should_receive,
          :stub, :stub!, :stub_chain, :unstub, :unstub!
        ])
      end

      it 'limits the number of methods that get added to all classes ' do
        # If really necessary, you can add to this list, but long term,
        # we are hoping to cut down on the number of methods added to all classes
        expect(added_methods(Class, RSpec::Mocks::AnyInstance)).to match_array([:any_instance])
      end
    end
  end
end

