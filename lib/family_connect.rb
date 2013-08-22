require "family_connect/version"

module FamilyConnect
  class Client
    attr_accessor :dev_key, :redirect_uri, :base_env, :env

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
  end
end
