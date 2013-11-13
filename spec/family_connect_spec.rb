require 'spec_helper'
require 'typhoeus'

describe FamilyConnect::Client do
  before do
    discovery = File.read(File.join('spec/sampledata/discovery.response'))
    response = Typhoeus::Response.new(code: 200, body: discovery)
    Typhoeus.stub(/well-known\/app-meta/).and_return(response)
  end

  it 'should set defaults' do
    family_connect_client = FamilyConnect::Client.new({:dev_key => '123', :env => 'sandbox', :redirect_uri => 'http://localhost:8080/oath'})
    family_connect_client.dev_key.should == '123'
    family_connect_client.env.should == 'sandbox'
    family_connect_client.redirect_uri.should == 'http://localhost:8080/oath'
  end

  it 'should set base_env for all environments' do
    family_search = FamilyConnect::Client.new({:dev_key => '123', :env => 'sandbox', :redirect_uri => 'http://localhost:8080/oath'})
    family_search.base_env.should == 'sandbox'

    family_search = FamilyConnect::Client.new({:dev_key => '123', :env => 'staging', :redirect_uri => 'http://localhost:8080/oath'})
    family_search.base_env.should == 'identbeta'

    family_search = FamilyConnect::Client.new({:dev_key => '123', :env => 'production', :redirect_uri => 'http://localhost:8080/oath'})
    family_search.base_env.should == 'ident'
  end

  it 'should discover family search apis' do
    family_search = FamilyConnect::Client.new({:dev_key => '123', :env => 'sandbox', :redirect_uri => 'http://localhost:8080/oath'})
    discover = family_search.discover
    discover['links']["http://oauth.net/core/2.0/endpoint/authorize"]['href'].should == "https://sandbox.familysearch.org/cis-web/oauth2/v3/authorization"
  end

  it 'should get and set access_token' do
    family_search = FamilyConnect::Client.new({:dev_key => '123', :env => 'sandbox', :redirect_uri => 'http://localhost:8080/oath'})
    family_search.access_token = '123'
    family_search.access_token.should == '123'
  end


  it 'should get current user' do
    current_user = '{"users" : [{"id" : "cis.MMM.RX9", "links" : {"self" : {"href" : "https://familysearch.org/platform/users/current"}}, "contactName" : "Pete Townsend", "fullName" : "Pete Townsend", "email" : "peter@acme.org", "treeUserId" : "PXRQ-FMXT"}]}'
    response = Typhoeus::Response.new(code: 200, body: current_user)
    Typhoeus.stub(/familysearch.org\/platform\/users\/current/).and_return(response)
    family_search = FamilyConnect::Client.new({:dev_key => '123', :env => 'sandbox', :redirect_uri => 'http://localhost:8080/oath'})
    result = family_search.get_current_user 'access cod'
    result.should == JSON.parse(current_user)
  end

  it 'should throw exception if access code is nil' do
    current_user = '{"users" : [{"id" : "cis.MMM.RX9", "links" : {"self" : {"href" : "https://familysearch.org/platform/users/current"}}, "contactName" : "Pete Townsend", "fullName" : "Pete Townsend", "email" : "peter@acme.org", "treeUserId" : "PXRQ-FMXT"}]}'
    response = Typhoeus::Response.new(code: 200, body: current_user)
    Typhoeus.stub(/familysearch.org\/platform\/users\/current/).and_return(response)
    family_search = FamilyConnect::Client.new({:dev_key => '123', :env => 'sandbox', :redirect_uri => 'http://localhost:8080/oath'})
    expect {family_search.get_current_user nil}.to raise_error(FamilyConnect::Error::BadAccessToken)
  end

  describe '#template' do


    it 'should find a template from the discover and return a template object' do
      family_search = FamilyConnect::Client.new({:dev_key => '123', :env => 'sandbox', :redirect_uri => 'http://localhost:8080/oath'})
      template = family_search.template('person-restore-template')
      template.should be_instance_of(FamilyConnect::Template)
      template.title.should == 'Restore'
    end

    it 'should raise an error if the template is not found' do
      family_search = FamilyConnect::Client.new({:dev_key => '123', :env => 'sandbox', :redirect_uri => 'http://localhost:8080/oath'})
      expect {family_search.template('foo-template')}.to raise_error(FamilyConnect::Error::TemplateNotFound)
    end

    it 'should find template without -template' do
      family_search = FamilyConnect::Client.new({:dev_key => '123', :env => 'sandbox', :redirect_uri => 'http://localhost:8080/oath'})
      template = family_search.template('person-restore')
      template.should be_instance_of(FamilyConnect::Template)
      template.title.should == 'Restore'
    end

    it 'should find template without -query' do
      family_search = FamilyConnect::Client.new({:dev_key => '123', :env => 'sandbox', :redirect_uri => 'http://localhost:8080/oath'})
      template = family_search.template('ancestry')
      template.should be_instance_of(FamilyConnect::Template)
      template.title.should == 'Ancestry'
    end

  end

  describe '#oath' do
    it 'should return the authorization uri' do
      family_search = FamilyConnect::Client.new({:dev_key => '123', :env => 'sandbox', :redirect_uri => 'http://localhost:8080/oath'})
      family_search.authorize_url.should == family_search.discovery['links']["http://oauth.net/core/2.0/endpoint/authorize"]["href"]
    end

    it 'should get oath token' do
      response = Typhoeus::Response.new(code: 200, body: '{"access_token":"123456789"}')
      Typhoeus.stub(/oauth2\/v3\/token/).and_return(response)
      family_search = FamilyConnect::Client.new({:dev_key => '123', :env => 'sandbox', :redirect_uri => 'http://localhost:8080/oath'})
      token = family_search.get_token '1458-101412255-74501275-11588-1107268821-10985-2557792193-124-79-53-97-124-8636-32'
      token.should == {"access_token" => "123456789"}
      family_search.access_token.should == "123456789"
    end

    it 'should handle error from bad oath token' do
      response = Typhoeus::Response.new(code: 200, body: '{"error_description" : "Client not found. [ clientId: 123 ].", "error" : "invalid_grant"}')
      Typhoeus.stub(/oauth2\/v3\/token/).and_return(response)
      family_search = FamilyConnect::Client.new({:dev_key => '123', :env => 'sandbox', :redirect_uri => 'http://localhost:8080/oath'})
      token = family_search.get_token '1458-101412255-74501275-11588-1107268821-10985-2557792193-124-79-53-97-124-8636'
      token.should == {"error_description"=>"Client not found. [ clientId: 123 ].", "error"=>"invalid_grant"}
      family_search.access_token.should be_nil
    end

    it 'should delete an access_token' do
      response = Typhoeus::Response.new(code: 204, body: '')
      Typhoeus.stub(/oauth2\/v3\/token/).and_return(response)
      family_search = FamilyConnect::Client.new({:dev_key => '123', :env => 'sandbox', :redirect_uri => 'http://localhost:8080/oath'})
      family_search.access_token = "123456789"
      family_search.access_token.should == "123456789"
      token = family_search.delete_token '2YoTnFdFEjr1zCsicMWpAA'
      token.should == {"access_token" => nil}
      family_search.access_token.should be_nil
    end

  end


  #
  #it 'should get access token' do
  #  #TO_DO test to mmake sure it is calling the right url etc... not sure how to do this just yet
  #  Typhoeus::Request.any_instance.stub(:run){Typhoeus::Response.new({:code => 200, :body => '{"access_token":"123456789"}'})}
  #  #mock.instance_of(Typhoeus::Request).run {Typhoeus::Response.new({:code => 200, :body => '{"access_token":"123456789"}'})}
  #  code = '123'
  #  family_search = FamilyConnect::Client.new({:dev_key => '123', :env => 'sandbox', :redirect_uri => 'http://localhost:8080/oath'})
  #  family_search.get_access_token(code).should == {"access_token" =>"123456789"}
  #end
end