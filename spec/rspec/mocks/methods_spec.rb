require "spec_helper"

include RSpec::Mocks::Methods

describe "Methods" do 
  before do 
    @user = double("nobi")
  end

  context "should_recieve" do 
  end

  context "stub method" do 
    it "when mesage_or_hash is Hash" do 
      @user.stub(:count => 37).should == {:count => 37}
    end

    it "when message_or_hash is not Hash" do
      @user.stub(:count).and_return(37).call.should == 37
    end
  end

  context "stub chain" do 
    it "given stub_chain('foo.bar')" do
      @user.stub_chain("foo.bar"){:baz}
      @user.foo.bar.should == :baz 
    end
    it "when given stub_chain(:foo , :bar => :baz)" do
      @user.stub_chain("foo.bar"){:baz}
      @user.foo.bar.should == :baz
    end
  end

  context "null_object?" do 
    it "should return true when null_object? is true" do 
      @user.as_null_object
      @user.null_object?.should == true
    end
    it "should return false when received as_null_object?" do 
      @user.null_object?.should == false
    end
  end

end
