# frozen_string_literal: true

require_relative "base_provider"
require "net/http"
require "uri"
require "json"
require "openssl"

module Sphragis
  module Providers
    # Fortify by Peculiar Ventures Provider
    # Uses Fortify WebCrypto bridge to access hardware tokens
    #
    # @see https://github.com/PeculiarVentures/fortify-releases
    #
    # Requirements:
    # - Fortify app running (FREE - https://github.com/PeculiarVentures/fortify-releases)
    # - PKCS#11 library installed (OpenSC - FREE)
    # - Hardware token (YubiKey, Nitrokey, etc.)
    #
    # License: MIT (FREE for all use)
    class FortifyWebcryptoProvider < BaseProvider
      FORTIFY_DEFAULT_URL = "https://localhost:31337"

      # Initialize Fortify WebCrypto provider
      # @param config [Hash] Configuration options
      #   - api_url: Fortify API URL (default: https://localhost:31337)
      #   - token_pin: Hardware token PIN
      #   - certificate_id: Certificate identifier on token
      #   - verify_ssl: Verify SSL (default: false for localhost)
      def initialize(config = {})
        super
        @config = {
          api_url: config[:api_url] || FORTIFY_DEFAULT_URL,
          token_pin: config[:token_pin],
          certificate_id: config[:certificate_id],
          verify_ssl: config[:verify_ssl] || false
        }
        @http = setup_http_client
      end

      def connect
        validate_configuration!

        # Check if Fortify is running
        unless fortify_running?
          raise ProviderError, "Fortify app is not running. Start it with: fortify"
        end

        # List available providers (tokens)
        providers = list_providers

        if providers.empty?
          raise ProviderError, "No hardware tokens detected. Please insert your token."
        end

        # Get the first available provider
        @provider_id = providers.first["id"]

        # Login to token with PIN
        login(@provider_id, @config[:token_pin])

        @session = {
          connected: true,
          provider: "fortify_webcrypto",
          provider_id: @provider_id,
          fortify_url: @config[:api_url]
        }
        true
      rescue StandardError => e
        raise ProviderError, "Failed to connect to Fortify: #{e.message}"
      end

      def disconnect
        # Logout from token
        logout(@session[:provider_id]) if @session
        @session = nil
        true
      end

      def sign(data)
        raise ProviderError, "Not connected to Fortify" unless connected?

        # Get certificate from token
        cert_id = @config[:certificate_id] || find_signing_certificate

        # Sign data using WebCrypto API
        signature_result = sign_with_webcrypto(cert_id, data)

        {
          provider: "fortify_webcrypto",
          algorithm: signature_result[:algorithm],
          signature: signature_result[:signature],
          timestamp: Time.now.utc.iso8601,
          certificate_id: cert_id,
          hardware_token: true
        }
      rescue StandardError => e
        raise ProviderError, "Failed to sign with Fortify: #{e.message}"
      end

      def certificate
        raise ProviderError, "Not connected to Fortify" unless connected?

        cert_id = @config[:certificate_id] || find_signing_certificate
        cert_info = get_certificate_info(cert_id)

        {
          provider: "fortify_webcrypto",
          subject: cert_info[:subject],
          issuer: cert_info[:issuer],
          serial: cert_info[:serial],
          not_before: cert_info[:not_before],
          not_after: cert_info[:not_after],
          key_usage: cert_info[:key_usage],
          hardware_backed: true
        }
      end

      def validate_configuration!
        raise ProviderError, "Token PIN not configured" if @config[:token_pin].nil?
      end

      # Check if Fortify app is running
      # @return [Boolean]
      def fortify_running?
        response = make_request(:get, "/info")
        response.is_a?(Hash) && response["name"] == "fortify"
      rescue StandardError
        false
      end

      # Get Fortify version info
      # @return [Hash]
      def fortify_info
        make_request(:get, "/info")
      end

      private

      def setup_http_client
        uri = URI.parse(@config[:api_url])
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"
        http.verify_mode = @config[:verify_ssl] ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE
        http.read_timeout = 30
        http
      end

      def make_request(method, path, body = nil)
        uri = URI.parse("#{@config[:api_url]}#{path}")

        request = case method
                  when :get
                    Net::HTTP::Get.new(uri.path)
                  when :post
                    req = Net::HTTP::Post.new(uri.path)
                    req.body = body.to_json if body
                    req["Content-Type"] = "application/json"
                    req
                  end

        response = @http.request(request)

        if response.code.to_i >= 400
          raise ProviderError, "Fortify API error: #{response.code} - #{response.body}"
        end

        JSON.parse(response.body)
      rescue JSON::ParserError
        response.body
      end

      def list_providers
        # GET /providers - List available PKCS#11 providers (tokens)
        make_request(:get, "/providers")
      end

      def login(provider_id, pin)
        # POST /providers/{id}/login
        make_request(:post, "/providers/#{provider_id}/login", { pin: pin })
      end

      def logout(provider_id)
        # POST /providers/{id}/logout
        make_request(:post, "/providers/#{provider_id}/logout")
      rescue StandardError
        # Ignore logout errors
        true
      end

      def find_signing_certificate
        # GET /providers/{id}/keys - List keys/certificates
        keys = make_request(:get, "/providers/#{@session[:provider_id]}/keys")

        # Find first key with signing capability
        signing_key = keys.find do |key|
          key["usages"]&.include?("sign") || key["type"] == "private"
        end

        raise ProviderError, "No signing certificate found on token" unless signing_key

        signing_key["id"]
      end

      def sign_with_webcrypto(key_id, data)
        # POST /providers/{provider_id}/keys/{key_id}/sign
        # Use WebCrypto API to sign
        payload = {
          algorithm: {
            name: "RSASSA-PKCS1-v1_5",
            hash: "SHA-256"
          },
          data: Base64.strict_encode64(data)
        }

        result = make_request(
          :post,
          "/providers/#{@session[:provider_id]}/keys/#{key_id}/sign",
          payload
        )

        {
          algorithm: "SHA256withRSA",
          signature: result["signature"]
        }
      end

      def get_certificate_info(cert_id)
        # GET /providers/{provider_id}/certificates/{cert_id}
        cert_data = make_request(
          :get,
          "/providers/#{@session[:provider_id]}/certificates/#{cert_id}"
        )

        # Parse certificate
        cert = OpenSSL::X509::Certificate.new(
          Base64.decode64(cert_data["value"])
        )

        {
          subject: cert.subject.to_s,
          issuer: cert.issuer.to_s,
          serial: cert.serial.to_s,
          not_before: cert.not_before,
          not_after: cert.not_after,
          key_usage: extract_key_usage(cert)
        }
      end

      def extract_key_usage(cert)
        usage_ext = cert.extensions.find { |ext| ext.oid == "keyUsage" }
        return [] unless usage_ext

        usage_ext.value.split(", ")
      end
    end
  end
end
