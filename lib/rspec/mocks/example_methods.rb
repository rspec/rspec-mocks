require 'rspec/mocks/object_reference'

module RSpec
  module Mocks
    module ExampleMethods
      include RSpec::Mocks::ArgumentMatchers

      # @overload double()
      # @overload double(name)
      # @overload double(stubs)
      # @overload double(name, stubs)
      # @param name [String/Symbol] (optional) used in
      #   clarify intent
      # @param stubs (Hash) (optional) hash of message/return-value pairs
      # @return (Double)
      #
      # Constructs an instance of [RSpec::Mocks::Double](RSpec::Mocks::Double) configured
      # with an optional name, used for reporting in failure messages, and an optional
      # hash of message/return-value pairs.
      #
      # @example
      #
      #   book = double("book", :title => "The RSpec Book")
      #   book.title #=> "The RSpec Book"
      #
      #   card = double("card", :suit => "Spades", :rank => "A")
      #   card.suit  #=> "Spades"
      #   card.rank  #=> "A"
      #
      def double(*args)
        ExampleMethods.declare_double(Double, *args)
      end

      # @overload instance_double(doubled_class)
      # @overload instance_double(doubled_class, stubs)
      # @param doubled_class [String, Class]
      # @param stubs [Hash] (optional) hash of message/return-value pairs
      # @return InstanceVerifyingDouble
      #
      # Constructs a test double against a specific class. If the given class
      # name has been loaded, only instance methods defined on the class are
      # allowed to be stubbed. In all other ways it behaves like a
      # [double](double).
      def instance_double(doubled_class, *args)
        ref = ObjectReference.for(doubled_class)
        ExampleMethods.declare_verifying_double(InstanceVerifyingDouble, ref, *args)
      end

      # @overload class_double(doubled_class)
      # @overload class_double(doubled_class, stubs)
      # @param doubled_class [String, Module]
      # @param stubs [Hash] (optional) hash of message/return-value pairs
      # @return ClassVerifyingDouble
      #
      # Constructs a test double against a specific class. If the given class
      # name has been loaded, only class methods defined on the class are
      # allowed to be stubbed. In all other ways it behaves like a
      # [double](double).
      def class_double(doubled_class, *args)
        ref = ObjectReference.for(doubled_class)
        ExampleMethods.declare_verifying_double(ClassVerifyingDouble, ref, *args)
      end

      # @overload object_double(object_or_name)
      # @overload object_double(object_or_name, stubs)
      # @param object_or_name [String, Object]
      # @param stubs [Hash] (optional) hash of message/return-value pairs
      # @return ObjectVerifyingDouble
      #
      # Constructs a test double against a specific object. Only the methods
      # the object responds to are allowed to be stubbed. If a String argument
      # is provided, it is assumed to reference a constant object which is used
      # for verification. In all other ways it behaves like a [double](double).
      def object_double(object_or_name, *args)
        ref = ObjectReference.for(object_or_name, :allow_direct_object_refs)
        ExampleMethods.declare_verifying_double(ObjectVerifyingDouble, ref, *args)
      end

      # Disables warning messages about expectations being set on nil.
      #
      # By default warning messages are issued when expectations are set on
      # nil.  This is to prevent false-positives and to catch potential bugs
      # early on.
      def allow_message_expectations_on_nil
        RSpec::Mocks.space.proxy_for(nil).warn_about_expectations = false
      end

      # Stubs the named constant with the given value.
      # Like method stubs, the constant will be restored
      # to its original value (or lack of one, if it was
      # undefined) when the example completes.
      #
      # @param constant_name [String] The fully qualified name of the constant. The current
      #   constant scoping at the point of call is not considered.
      # @param value [Object] The value to make the constant refer to. When the
      #   example completes, the constant will be restored to its prior state.
      # @param options [Hash] Stubbing options.
      # @option options :transfer_nested_constants [Boolean, Array<Symbol>] Determines
      #   what nested constants, if any, will be transferred from the original value
      #   of the constant to the new value of the constant. This only works if both
      #   the original and new values are modules (or classes).
      # @return [Object] the stubbed value of the constant
      #
      # @example
      #
      #   stub_const("MyClass", Class.new) # => Replaces (or defines) MyClass with a new class object.
      #   stub_const("SomeModel::PER_PAGE", 5) # => Sets SomeModel::PER_PAGE to 5.
      #
      #   class CardDeck
      #     SUITS = [:Spades, :Diamonds, :Clubs, :Hearts]
      #     NUM_CARDS = 52
      #   end
      #
      #   stub_const("CardDeck", Class.new)
      #   CardDeck::SUITS # => uninitialized constant error
      #   CardDeck::NUM_CARDS # => uninitialized constant error
      #
      #   stub_const("CardDeck", Class.new, :transfer_nested_constants => true)
      #   CardDeck::SUITS # => our suits array
      #   CardDeck::NUM_CARDS # => 52
      #
      #   stub_const("CardDeck", Class.new, :transfer_nested_constants => [:SUITS])
      #   CardDeck::SUITS # => our suits array
      #   CardDeck::NUM_CARDS # => uninitialized constant error
      def stub_const(constant_name, value, options = {})
        ConstantMutator.stub(constant_name, value, options)
      end

      # Hides the named constant with the given value. The constant will be
      # undefined for the duration of the test.
      #
      # Like method stubs, the constant will be restored to its original value
      # when the example completes.
      #
      # @param constant_name [String] The fully qualified name of the constant.
      #   The current constant scoping at the point of call is not considered.
      #
      # @example
      #
      #   hide_const("MyClass") # => MyClass is now an undefined constant
      def hide_const(constant_name)
        ConstantMutator.hide(constant_name)
      end

      # Verifies that the given object received the expected message during the
      # course of the test. The method must have previously been stubbed in
      # order for messages to be verified.
      #
      # Stubbing and verifying messages received in this way implements the
      # Test Spy pattern.
      #
      # @param method_name [Symbol] name of the method expected to have been
      #   called.
      #
      # @example
      #
      #   invitation = double('invitation', accept: true)
      #   user.accept_invitation(invitation)
      #   expect(invitation).to have_received(:accept)
      #
      #   # You can also use most message expectations:
      #   expect(invitation).to have_received(:accept).with(mailer).once
      def have_received(method_name, &block)
        Matchers::HaveReceived.new(method_name, &block)
      end

      # @api private
      def self.included(klass)
        klass.class_exec do
          # This gets mixed in so that if `RSpec::Matchers` is included in
          # `klass` later, it's definition of `expect` will take precedence.
          include ExpectHost unless method_defined?(:expect)
        end
      end

      # @api private
      def self.declare_verifying_double(type, ref, *args)
        if RSpec::Mocks.configuration.verify_doubled_constant_names? &&
          !ref.defined?

          raise VerifyingDoubleNotDefinedError,
            "#{ref.description} is not a defined constant. " +
            "Perhaps you misspelt it? " +
            "Disable check with verify_doubled_constant_names configuration option."
        end

        declare_double(type, ref, *args)
      end

      # @api private
      def self.declare_double(type, *args)
        args << {} unless Hash === args.last
        type.new(*args)
      end

      # This module exists to host the `expect` method for cases where
      # rspec-mocks is used w/o rspec-expectations.
      module ExpectHost
      end
    end
  end
end
