# frozen_string_literal: true

module Sphragis
  class DocumentsController < ::ApplicationController
    # GET /sphragis/documents/:id/preview
    def preview
      @document_path = params[:path]
      @signature_options = {
        x: params[:x]&.to_i || 400,
        y: params[:y]&.to_i || 50,
        width: params[:width]&.to_i || 150,
        height: params[:height]&.to_i || 50,
        page: params[:page]&.to_i,
        provider: params[:provider]&.to_sym
      }

      @available_providers = ProviderFactory.available_providers
      @selected_provider = @signature_options[:provider] || ProviderFactory.default_provider

      if @document_path && File.exist?(@document_path)
        @signer = PdfSigner.new(@document_path, @signature_options)
        @pdf_info = @signer.pdf_info
      else
        render json: { error: "PDF file not found" }, status: :not_found
      end
    end

    # GET /sphragis/documents/:id/view
    def view
      document_path = params[:path]

      if document_path && File.exist?(document_path)
        send_file document_path, type: "application/pdf", disposition: "inline"
      else
        render json: { error: "PDF file not found" }, status: :not_found
      end
    end

    # POST /sphragis/documents/:id/sign
    def sign
      document_path = params[:path]
      signature_options = {
        x: params[:x]&.to_i,
        y: params[:y]&.to_i,
        width: params[:width]&.to_i,
        height: params[:height]&.to_i,
        page: params[:page]&.to_i,
        reason: params[:reason],
        location: params[:location],
        contact_info: params[:contact_info],
        provider: params[:provider]&.to_sym
      }.compact

      signer = PdfSigner.new(document_path, signature_options)
      signed_path = signer.sign

      render json: {
        success: true,
        signed_path: signed_path,
        provider: signer.provider.provider_name,
        message: "Document signed successfully with #{signer.provider.provider_name}"
      }
    rescue PdfSigner::SigningError => e
      render json: { error: e.message }, status: :unprocessable_entity
    rescue Providers::BaseProvider::ProviderError => e
      render json: { error: "Provider error: #{e.message}" }, status: :service_unavailable
    rescue ProviderFactory::ProviderNotConfiguredError => e
      render json: { error: e.message }, status: :precondition_failed
    end

    # GET /sphragis/documents/:id/validate_placement
    def validate_placement
      document_path = params[:path]
      x = params[:x].to_i
      y = params[:y].to_i
      page = params[:page]&.to_i

      signer = PdfSigner.new(document_path, { x: x, y: y, page: page })

      if signer.validate_placement(page)
        render json: { valid: true }
      else
        render json: { valid: false, error: "Invalid signature placement" }
      end
    rescue StandardError => e
      render json: { valid: false, error: e.message }, status: :unprocessable_entity
    end
  end
end
