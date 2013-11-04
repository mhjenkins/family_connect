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

    #def authorize_uri
    #  "https://#{@base_env}.familysearch.org/cis-web/oauth2/v3/authorization?response_type=code&client_id=#{@dev_key}&redirect_uri=#{@redirect_uri}"
    #end
    #
    #def get_access_token code
    #  response = Typhoeus::Request.new(
    #      "https://#{@base_env}.familysearch.org/cis-web/oauth2/v3/token",
    #      method: :post,
    #      body: "",
    #      params: { grant_type: "authorization_code", code: code, client_id: @dev_key },
    #      headers: { Accept: "text/html" }
    #  ).run
    #
    #  JSON.parse(response.body)
    #end

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
