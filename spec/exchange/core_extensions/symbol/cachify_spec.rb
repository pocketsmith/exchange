require 'spec_helper'

describe "Exchange::Cachify" do
  
  describe "cachify" do
    subject { :blu }
    it "should marshal dump" do
      subject.cachify.should == Marshal.dump(subject)
    end
  end
  
end