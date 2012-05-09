### Basics

Test doubles are objects that stand in as other objects for the purpose of your tests. 

The three methods `double`, `mock` and `stub` do the same thing; create an instance of the `RSpec::Mocks` class.

    # create a double using the `double` method
    obj = double()
    obj = double('kind-of-double')

    # or `mock` or `stub` methods
    obj = stub('kind-of-double')
    obj = mock('kind-of-double')

The string argument is optional but recommended, as it appears in failure messages. 
