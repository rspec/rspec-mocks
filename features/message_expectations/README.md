### Basics

    # create a double
    obj = double()

    # expect a message
    expect(obj).to receive(:message)

    # specify a return value
    expect(obj).to receive(:message) { :value }
    expect(obj).to receive(:message).and_return(:value)

    # specify multiple message/return value pairs
    expect(obj).to receive_messages(:message => :value, :another_message => :another_value)

These forms are somewhat interchangeable. The difference is that the
block contents are evaluated lazily when the `obj` receives the
`message` message, whereas the others are evaluated as they are read.

### Fake implementation

    expect(obj).to receive(:message) do |arg1, arg2|
      # set expectations about the args in this block
      # and set a return value
    end

### Using the original implementation

    expect(obj).to receive(:message).and_call_original

### Raising/Throwing

    expect(obj).to receive(:message).and_raise("this error")
    expect(obj).to receive(:message).and_throw(:this_symbol)

You can also use the block format:

    expect(obj).to receive(:message) { raise "this error" }
    expect(obj).to receive(:message) { throw :this_symbol }

### Argument constraints

#### Explicit arguments

    expect(obj).to receive(:message).with('an argument')
    expect(obj).to receive(:message).with('more_than', 'one_argument')

#### Argument matchers

    expect(obj).to receive(:message).with(anything())
    expect(obj).to receive(:message).with(an_instance_of(Money))
    expect(obj).to receive(:message).with(hash_including(:a => 'b'))

#### Regular expressions

    expect(obj).to receive(:message).with(/abc/)

### Counts

    expect(obj).to receive(:message).once
    expect(obj).to receive(:message).twice
    expect(obj).to receive(:message).exactly(3).times

    expect(obj).to receive(:message).at_least(:once)
    expect(obj).to receive(:message).at_least(:twice)
    expect(obj).to receive(:message).at_least(n).times

    expect(obj).to receive(:message).at_most(:once)
    expect(obj).to receive(:message).at_most(:twice)
    expect(obj).to receive(:message).at_most(n).times

### Ordering

    expect(obj).to receive(:one).ordered
    expect(obj).to receive(:two).ordered
