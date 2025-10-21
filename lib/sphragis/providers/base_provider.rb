# frozen_string_literal: true

module Sphragis
  module Providers
    class BaseProvider
      class ProviderError < StandardError; end

      attr_reader :config

      def initialize(config = {})
        @config = config
        @session = nil
      end

      # Connect to the signature provider
      # Must be implemented by subclasses
      def connect
        raise NotImplementedError, "#{self.class.name} must implement #connect"
      end

      # Disconnect from the provider
      # Must be implemented by subclasses
      def disconnect
        raise NotImplementedError, "#{self.class.name} must implement #disconnect"
      end

      # Check if connected
      def connected?
        !@session.nil?
      end

      # Sign data
      # Must be implemented by subclasses
      # @param data [String] Data to sign
      # @return [Hash] Signature information
      def sign(data)
        raise NotImplementedError, "#{self.class.name} must implement #sign"
      end

      # Get certificate information
      # Must be implemented by subclasses
      # @return [Hash] Certificate details
      def certificate
        raise NotImplementedError, "#{self.class.name} must implement #certificate"
      end

      # Get provider name
      # @return [String] Human-readable provider name
      def provider_name
        self.class.name.split("::").last.gsub("Provider", "")
      end

      # Validate configuration
      # Can be overridden by subclasses
      def validate_configuration!
        # Base implementation does nothing
        true
      end
    end
  end
end
