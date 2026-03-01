# frozen_string_literal: true

require "prawn"
require "pdf-reader"
require "json"

module Sphragis
  class PdfSigner
    class SigningError < StandardError; end

    attr_reader :pdf_path, :provider, :signature_options

    # Initialize with PDF path and optional signature placement
    # @param pdf_path [String] Path to the PDF file
    # @param signature_options [Hash] Options for signature placement
    #   - x: X coordinate (default: 400)
    #   - y: Y coordinate (default: 50)
    #   - width: Signature width (default: 150)
    #   - height: Signature height (default: 50)
    #   - page: Page number to sign (default: last page)
    #   - reason: Signing reason (default: "Document approval")
    #   - location: Signing location (default: nil)
    #   - provider: Signature provider (:fortify, :harica, :itsme) (default: configured default)
    def initialize(pdf_path, signature_options = {})
      @pdf_path = pdf_path
      @signature_options = default_signature_options.merge(signature_options)

      # Create provider based on options or use default.
      # OTP and placement params are forwarded to the provider so that
      # cloud providers (e.g. Harica) receive everything they need at sign time.
      provider_name  = @signature_options.delete(:provider) || ProviderFactory.default_provider
      provider_extra = {
        otp:      @signature_options.delete(:otp),
        x:        @signature_options[:x],
        y:        @signature_options[:y],
        width:    @signature_options[:width],
        height:   @signature_options[:height],
        page:     @signature_options[:page],
        reason:   @signature_options[:reason],
        location: @signature_options[:location]
      }.compact
      @provider = ProviderFactory.create(provider_name, provider_extra)

      validate_pdf!
    end

    # Sign the PDF document
    # @return [String] Path to the signed PDF
    def sign
      raise SigningError, "PDF file does not exist: #{pdf_path}" unless File.exist?(pdf_path)

      @provider.connect

      # Pass raw PDF bytes to the provider. Cloud providers (Harica) send the
      # full PDF to their API; hardware-token providers hash the content locally.
      signature = @provider.sign(File.binread(pdf_path))

      # Create signed PDF
      signed_pdf_path = create_signed_pdf(signature)

      @provider.disconnect

      signed_pdf_path
    rescue StandardError => e
      @provider&.disconnect
      raise SigningError, "Failed to sign PDF: #{e.message}"
    end

    # Get PDF metadata
    def pdf_info
      reader = PDF::Reader.new(pdf_path)
      {
        page_count: reader.page_count,
        pdf_version: reader.pdf_version,
        info: reader.info,
        metadata: reader.metadata
      }
    end

    # Validate signature placement on a specific page
    def validate_placement(page_number = nil)
      page = page_number || signature_options[:page] || pdf_info[:page_count]
      info = pdf_info

      raise SigningError, "Invalid page number: #{page}" if page > info[:page_count] || page < 1

      true
    end

    private

    def default_signature_options
      {
        x: 400,
        y: 50,
        width: 150,
        height: 50,
        page: nil, # nil means last page
        reason: "Document approval",
        location: nil,
        contact_info: nil
      }
    end

    def validate_pdf!
      raise SigningError, "PDF path cannot be nil" if pdf_path.nil?
      raise SigningError, "PDF file does not exist: #{pdf_path}" unless File.exist?(pdf_path)

      # Validate it's a valid PDF
      PDF::Reader.new(pdf_path)
    rescue PDF::Reader::MalformedPDFError => e
      raise SigningError, "Invalid PDF file: #{e.message}"
    end

    def create_signed_pdf(signature)
      output_path = pdf_path.sub(/\.pdf$/i, "_signed.pdf")

      if signature[:signed_pdf_bytes]
        # Cloud provider (e.g. Harica) returned a fully signed PDF — write it directly.
        File.binwrite(output_path, signature[:signed_pdf_bytes])
      else
        # Local/simulated provider: copy original PDF and write a JSON sidecar.
        create_signed_pdf_with_prawn(output_path, signature)
      end

      output_path
    end

    def create_signed_pdf_with_prawn(output_path, signature)
      # Copy original PDF and add signature annotation
      FileUtils.cp(pdf_path, output_path)

      # In production, this would embed the actual signature into the PDF
      # using proper PDF signing standards (ISO 32000)

      # Add signature metadata to a separate file for demonstration
      require "time"
      metadata_path = output_path.sub(/\.pdf$/i, "_signature.json")
      File.write(metadata_path, JSON.pretty_generate({
        signature: signature,
        certificate: @provider.certificate,
        provider: @provider.provider_name,
        signed_at: Time.now.utc.iso8601,
        signature_options: signature_options
      }))
    end
  end
end
