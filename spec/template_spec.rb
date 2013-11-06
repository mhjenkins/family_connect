require "spec_helper"
require 'typhoeus'
#let(:discovery){JSON.parse(File.read(File.join(Rails.root, 'spec/sampledata/discovery')))}
describe FamilyConnect::Template do
  before do
    @discovery = JSON.parse(File.read(File.join('spec/sampledata/discovery.response')))
    @client = FamilyConnect::Client.new({:dev_key => '123', :env => 'sandbox', :redirect_uri => 'http://localhost:8080/oath'})
    @client.access_token = '123'
  end

  describe 'initalize' do
    it 'should accept client and template hash' do
      hash = @discovery['links']['person-restore-template']
      template = FamilyConnect::Template.new({:client => @client,:template => hash})
      template.client.should == @client
      template.template.should == hash['template']
      template.type.should == hash['type']
      template.accept.should == hash['accept']
      template.allow.should == hash['allow']
      template.title.should == hash['title']
    end

    it 'should raise a template not found error if no template is found' do
      hash = @discovery['links']['person-restore-template']
      expect {FamilyConnect::Template.new({:client => @client})}.to raise_error(FamilyConnect::Error::TemplateNotFound)
    end
  end



  describe 'get'do
    it 'should return response' do
      Typhoeus::Request.any_instance.stub(:run){Typhoeus::Response.new({:code => 200, :body => '{"access_token":"123456789"}'})}
      hash = @discovery['links']['person-change-summary-template']
      template = FamilyConnect::Template.new({:client => @client,:template => hash})
      response = template.get({:pid => '1'})
      response["access_token"].should == "123456789"
    end

    it'should raise an error if get is not allowed' do
      hash = @discovery['links']['person-restore-template']
      template = FamilyConnect::Template.new({:client => @client,:template => hash})
      expect {template.get }.to raise_error(FamilyConnect::Error::MethodNotAllowed)

    end

    it 'should raise an error if the value is not found' do
      hash = @discovery['links']['person-change-summary-template']
      template = FamilyConnect::Template.new({:client => @client,:template => hash})
      expect {template.get ({:bob => 'dude'})}.to raise_error(FamilyConnect::Error::TemplateValueNotFound)
    end

    it 'should raise an error if the required values are not given'do
      hash = @discovery['links']['person-change-summary-template']
      template = FamilyConnect::Template.new({:client => @client,:template => hash})
      expect {template.get ({})}.to raise_error(FamilyConnect::Error::TemplateValueMissing)
    end
  end

  describe 'post'do
    xit 'should return response' do
      Typhoeus::Request.any_instance.stub(:run){Typhoeus::Response.new({:code => 200, :body => '{"access_token":"123456789"}'})}
      hash = @discovery['links']['person-restore-template']
      template = FamilyConnect::Template.new({:client => @client,:template => hash})
      response = template.post
      response["access_token"].should == "123456789"
    end

    it 'should raise an error if post is not allowed' do
      hash = @discovery['links']['person-change-summary-template']
      template = FamilyConnect::Template.new({:client => @client,:template => hash})
      expect {template.post }.to raise_error(FamilyConnect::Error::MethodNotAllowed)

    end
  end
end