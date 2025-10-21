# frozen_string_literal: true

module Sphragis
  class Configuration
    attr_accessor :default_provider

    # Fortify configuration
    attr_accessor :fortify_library_path, :token_pin, :token_slot, :certificate_label

    # Harica configuration
    attr_accessor :harica_api_key, :harica_certificate_id, :harica_username,
                  :harica_password, :harica_environment

    # Itsme configuration
    attr_accessor :itsme_client_id, :itsme_client_secret, :itsme_user_email,
                  :itsme_environment

    def initialize
      # Default provider
      @default_provider = ENV.fetch("SIGNATURE_PROVIDER", "fortify").to_sym

      # Fortify configuration
      @fortify_library_path = ENV.fetch("FORTIFY_LIBRARY_PATH", "/usr/lib/fortify/libfortify.so")
      @token_pin = ENV["FORTIFY_TOKEN_PIN"]
      @token_slot = ENV.fetch("FORTIFY_TOKEN_SLOT", "0").to_i
      @certificate_label = ENV.fetch("FORTIFY_CERTIFICATE_LABEL", "Signing Certificate")

      # Harica configuration
      @harica_api_key = ENV["HARICA_API_KEY"]
      @harica_certificate_id = ENV["HARICA_CERTIFICATE_ID"]
      @harica_username = ENV["HARICA_USERNAME"]
      @harica_password = ENV["HARICA_PASSWORD"]
      @harica_environment = ENV.fetch("HARICA_ENVIRONMENT", "production")

      # Itsme configuration
      @itsme_client_id = ENV["ITSME_CLIENT_ID"]
      @itsme_client_secret = ENV["ITSME_CLIENT_SECRET"]
      @itsme_user_email = ENV["ITSME_USER_EMAIL"]
      @itsme_environment = ENV.fetch("ITSME_ENVIRONMENT", "production")
    end

    # Get available providers based on configuration
    # @return [Array<Symbol>] List of configured providers
    def available_providers
      providers = []
      providers << :fortify if fortify_configured?
      providers << :harica if harica_configured?
      providers << :itsme if itsme_configured?
      providers
    end

    # Check if Fortify is configured
    def fortify_configured?
      !fortify_library_path.nil? && !token_pin.nil?
    end

    # Check if Harica is configured
    def harica_configured?
      !harica_api_key.nil? && !harica_certificate_id.nil? && !harica_username.nil?
    end

    # Check if Itsme is configured
    def itsme_configured?
      !itsme_client_id.nil? && !itsme_client_secret.nil? && !itsme_user_email.nil?
    end
  end

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
