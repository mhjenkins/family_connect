require 'spec_helper'
describe FamilyConnect::Client do
  it 'should set defaults' do
    family_connect_client = FamilyConnect::Client.new({:dev_key => '123', :env => 'sandbox', :redirect_uri => 'http://localhost:8080/oath'})
    family_connect_client.dev_key.should == '123'
    family_connect_client.env.should == 'sandbox'
    family_connect_client.redirect_uri.should == 'http://localhost:8080/oath'
  end
end