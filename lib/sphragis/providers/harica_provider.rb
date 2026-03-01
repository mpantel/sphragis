# frozen_string_literal: true

require_relative "base_provider"
require "base64"
require "net/http"
require "uri"
require "json"

module Sphragis
  module Providers
    # Harica (Hellenic Academic and Research Institutions CA) Provider
    #
    # Uses Harica's remote document signing API (rsign-api.harica.gr).
    # The API is a full-document cloud signer: you POST the PDF, Harica signs
    # it server-side and returns the complete signed PDF. No local key material
    # is needed. Authentication is per-request via username + password + OTP.
    #
    # OTP must be supplied per signing call (it rotates every ~30 s).
    # Pass it via PdfSigner options: PdfSigner.new(path, otp: "123456", provider: :harica)
    #
    # @see https://www.harica.gr
    class HaricaProvider < BaseProvider
      PRODUCTION_URL = "https://rsign-api.harica.gr/dsa/v1/sign"
      SANDBOX_URL    = "https://rsign-api-dev.harica.gr/dsa/v1/sign"

      def initialize(config = {})
        super
        @config = {
          username:            config[:username],
          password:            config[:password],
          otp:                 config[:otp],
          environment:         config[:environment] || "production",
          x:                   config[:x]      || 140,
          y:                   config[:y]      || 230,
          width:               config[:width]  || 150,
          height:              config[:height] || 100,
          page:                config[:page],    # nil → send -1 (all pages) to Harica
          reason:              config[:reason]  || "",
          graphical_signature: config[:graphical_signature] || ""
        }
      end

      # Validate credentials are present. The Harica API is stateless —
      # no persistent session is opened here.
      def connect
        validate_configuration!
        @session = { connected: true, provider: "harica" }
        true
      rescue StandardError => e
        raise ProviderError, "Failed to connect to Harica: #{e.message}"
      end

      def disconnect
        @session = nil
        true
      end

      # Sign a PDF document via Harica's remote signing API.
      #
      # @param pdf_bytes [String] raw binary content of the PDF file
      # @return [Hash] result hash; :signed_pdf_bytes contains the signed PDF
      def sign(pdf_bytes)
        raise ProviderError, "Not connected to Harica" unless connected?

        payload  = build_payload(pdf_bytes)
        response = post_to_harica(payload)
        parse_response(response)
      rescue ProviderError
        raise
      rescue StandardError => e
        raise ProviderError, "Failed to sign with Harica: #{e.message}"
      end

      # Harica's DSA API does not expose a certificate endpoint; return
      # descriptive metadata derived from the configured username instead.
      def certificate
        raise ProviderError, "Not connected to Harica" unless connected?

        {
          provider:         "harica",
          subject:          "CN=#{@config[:username]}, O=Harica User",
          issuer:           "CN=HARICA TLS RSA Root CA 2021, O=Hellenic Academic and Research Institutions CA",
          key_usage:        ["digitalSignature", "nonRepudiation"],
          certificate_type: "qualified"
        }
      end

      def validate_configuration!
        raise ProviderError, "Harica username not configured" if @config[:username].nil?
        raise ProviderError, "Harica password not configured" if @config[:password].nil?
        raise ProviderError, "Harica OTP not provided" if @config[:otp].nil?
      end

      private

      def api_url
        @config[:environment] == "sandbox" ? SANDBOX_URL : PRODUCTION_URL
      end

      # Harica uses -1 to sign all pages; otherwise a 1-based page number.
      def harica_page
        @config[:page].nil? ? -1 : @config[:page]
      end

      def build_payload(pdf_bytes)
        {
          "Username"           => @config[:username],
          "Password"           => @config[:password],
          "SignPassword"       => @config[:otp],
          "FileData"           => Base64.encode64(pdf_bytes),
          "Reason"             => @config[:reason],
          "Title"              => "",
          "FileType"           => "pdf",
          "Page"               => harica_page,
          "Width"              => @config[:width],
          "Height"             => @config[:height],
          "X"                  => @config[:x],
          "Y"                  => @config[:y],
          "Appearance"         => 15,
          "GraphicalSignature" => @config[:graphical_signature]
        }
      end

      def post_to_harica(payload)
        uri  = URI.parse(api_url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl      = uri.scheme == "https"
        http.read_timeout = 30
        http.open_timeout = 10

        request = Net::HTTP::Post.new(uri.path, "Content-Type" => "application/json")
        request.body = payload.to_json
        http.request(request)
      rescue Net::OpenTimeout, Net::ReadTimeout => e
        raise ProviderError, "Harica API request timed out: #{e.message}"
      end

      def parse_response(http_response)
        unless http_response.is_a?(Net::HTTPSuccess)
          raise ProviderError, "Harica API returned HTTP #{http_response.code}: #{http_response.message}"
        end

        body = JSON.parse(http_response.body)
        unless body["Success"]
          error_msg = body["Message"] || body["Error"] || "Unknown error"
          raise ProviderError, "Harica signing failed: #{error_msg}"
        end

        signed_pdf_bytes = Base64.decode64(body["Data"]["SignedFileData"])
        {
          provider:         "harica",
          algorithm:        "SHA256withRSA",
          signature_format: "CAdES",
          signed_pdf_bytes: signed_pdf_bytes,
          signed_at:        Time.now.utc.iso8601
        }
      end
    end
  end
end
