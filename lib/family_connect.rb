require "family_connect/version"
require 'family_connect/template'
require 'family_connect/error'
require "json"

module FamilyConnect
  class Client
    attr_accessor :dev_key, :redirect_uri, :base_env, :discovery, :access_token

    SANDBOX = 'sandbox'.freeze
    STAGING = 'identbeta'.freeze
    PRODUCTION = 'ident'.freeze

    def initialize args
      @dev_key = args[:dev_key]
      self.env = args[:env].downcase
      @redirect_uri = args[:redirect_uri].downcase
    end

    def env=(env)
      @env = env
      @base_env = SANDBOX
      if (@env == 'staging')
        @base_env = STAGING
      elsif (@env == 'production')
        @base_env = PRODUCTION
      end
    end

    def env
      @env
    end

    def authorize_url
      self.discover
      @discovery['links']["http://oauth.net/core/2.0/endpoint/authorize"]["href"]
    end

    def get_token code
      self.discover
      token_url =  @discovery['links']["http://oauth.net/core/2.0/endpoint/token"]["href"]
      params = {grant_type: "authorization_code", code: code, client_id: @dev_key }
      headers = {Accept: "text/html"}
      response = make_request(:url => token_url, :method => :post, :params => params, :headers => headers)
      @access_token = response["access_token"]
      response
    end

    def delete_token token
      self.discover
      token_url =  @discovery['links']["http://oauth.net/core/2.0/endpoint/token"]["href"]+"?access_token=#{token}"
      params = {}
      headers = {}
      response = make_request(:url => token_url, :method => :delete, :params => params, :headers => headers)
      if(response['response'] == 204)
        @access_token = nil
        return {'access_token' => nil}
      end

      response
    end

    def get_current_user access_token
      raise FamilyConnect::Error::BadAccessToken unless access_token

      self.discover
      current_user_url =  @discovery['links']["current-user"]["href"]
      params = {}
      headers = {Accept: 'application/x-fs-v1+json', Authorization: "Bearer #{access_token}"}
      make_request(:url => current_user_url, :method => :post, :params => params, :headers => headers)
    end

    def discover
      url = "https://#{@base_env}.familysearch.org/.well-known/app-meta.json"
      params = {}
      headers = {}
      @discovery ||= make_request(:url => url, :params => params, :headers => headers)
    end

    def template t_name
      self.discover
      template = @discovery['links'][t_name] || @discovery['links'][t_name+'-template'] || @discovery['links'][t_name+'-query']
      FamilyConnect::Template.new({:client => self,:template => template})
    end

    #private
    def make_request(parameters)
      method = parameters[:method] || :get
      url = parameters[:url]
      params = parameters[:params] || nil
      headers = parameters[:headers] || nil
      body = parameters[:body] || nil
      response = nil
      #begin
      #  Timeout::timeout(ApiConnection::TIMEOUT) do
          response = Typhoeus::Request.new(
              url,
              :method  => method,
              :body    => body,
              :params  => params,
              :headers => headers
          ).run
        #end
      #rescue Timeout::Error
      #  return {:error => 'timeout'}
      #end
      #
      #unless [200, 201].include? response.code
      #  return {:error => 'response_code', :error_code => response.code, :error_message => response.body }
      #end
      if [204].include? response.code
        return {'response' => 204, 'body' => nil}
      end
      #
      #begin
      #  JSON.parse response.body, :symbolize_names => true
        JSON.parse response.body
      #rescue JSON::JSONError => ex
      #  return {:error => 'bad_json', :error_message => ex.message }
      #end

    end
  end
end
