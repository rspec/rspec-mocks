describe 'issue 229' do
  context 'when stubbing a method on any instance' do
    it 'must handle freeze and then duplication' do
      String.any_instance.stub(:any_method)

      foo = 'foo'.freeze
      expect { foobar = foo.dup.concat 'bar' }.to_not raise_error
    end
  end
end
