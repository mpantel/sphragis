# frozen_string_literal: true

require "pdf-reader"

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

      output_path = pdf_path.sub(/\.pdf$/i, "_signed.pdf")

      if @provider.respond_to?(:sign_bytes)
        sign_locally(output_path)
      else
        # Cloud provider (e.g. Harica) returns a fully signed PDF.
        signature = @provider.sign(File.binread(pdf_path))
        File.binwrite(output_path, signature[:signed_pdf_bytes])
      end

      @provider.disconnect

      output_path
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

    def sign_locally(output_path)
      require "easy_code_sign"
      cert = @provider.x509_certificate
      page = signature_options[:page] || pdf_info[:page_count]
      pdf_file = EasyCodeSign::Signable::PdfFile.new(
        pdf_path,
        output_path: output_path,
        visible_signature: true,
        signature_rect: build_signature_rect,
        signature_page: page,
        signature_reason: signature_options[:reason],
        signature_location: signature_options[:location],
        signature_contact: signature_options[:contact_info]
      )
      # The lambda receives SHA256(signed_attrs_DER) — sign_bytes must return raw RSA bytes.
      pdf_file.apply_signature(->(hash) { @provider.sign_bytes(hash) }, [cert])
    end

    def build_signature_rect
      x = signature_options[:x]
      y = signature_options[:y]
      [x, y, x + signature_options[:width], y + signature_options[:height]]
    end
  end
end
