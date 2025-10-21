# frozen_string_literal: true

module Sphragis
  class ProviderFactory
    class ProviderNotFoundError < StandardError; end
    class ProviderNotConfiguredError < StandardError; end

    # Create a signature provider instance
    # @param provider_name [Symbol, String] Provider name (:fortify, :harica, :itsme)
    # @param config [Hash] Optional provider-specific configuration
    # @return [Providers::BaseProvider] Provider instance
    def self.create(provider_name, config = {})
      provider_name = provider_name.to_sym
      config_obj = Sphragis.configuration

      case provider_name
      when :fortify
        raise ProviderNotConfiguredError, "Fortify is not configured" unless config_obj.fortify_configured?

        require_relative "providers/fortify_provider"
        Providers::FortifyProvider.new(config)

      when :harica
        raise ProviderNotConfiguredError, "Harica is not configured" unless config_obj.harica_configured?

        require_relative "providers/harica_provider"
        Providers::HaricaProvider.new(config.empty? ? harica_config : config)

      when :itsme
        raise ProviderNotConfiguredError, "Itsme is not configured" unless config_obj.itsme_configured?

        require_relative "providers/itsme_provider"
        Providers::ItsmeProvider.new(config.empty? ? itsme_config : config)

      else
        raise ProviderNotFoundError, "Unknown provider: #{provider_name}. Available: #{available_providers.join(', ')}"
      end
    end

    # Get list of available (configured) providers
    # @return [Array<Symbol>] List of provider names
    def self.available_providers
      Sphragis.configuration.available_providers
    end

    # Get default provider
    # @return [Symbol] Default provider name
    def self.default_provider
      Sphragis.configuration.default_provider
    end

    # Create default provider instance
    # @return [Providers::BaseProvider] Default provider instance
    def self.create_default
      create(default_provider)
    end

    private

    def self.harica_config
      config = Sphragis.configuration
      {
        api_key: config.harica_api_key,
        certificate_id: config.harica_certificate_id,
        username: config.harica_username,
        password: config.harica_password,
        environment: config.harica_environment
      }
    end

    def self.itsme_config
      config = Sphragis.configuration
      {
        client_id: config.itsme_client_id,
        client_secret: config.itsme_client_secret,
        user_email: config.itsme_user_email,
        environment: config.itsme_environment
      }
    end
  end
end
