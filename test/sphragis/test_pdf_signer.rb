# frozen_string_literal: true

require "test_helper"

module Sphragis
  class TestPdfSigner < Minitest::Test
    def setup
      super
      Sphragis.configure do |config|
        config.fortify_library_path = "/usr/lib/fortify/libfortify.so"
        config.token_pin = "123456"
        config.token_slot = 0
        config.certificate_label = "Test Certificate"
      end

      @pdf_path = create_test_pdf
    end

    def test_initialization_with_valid_pdf
      signer = PdfSigner.new(@pdf_path)

      assert_instance_of PdfSigner, signer
      assert_equal @pdf_path, signer.pdf_path
      assert_kind_of Providers::BaseProvider, signer.provider
    end

    def test_initialization_with_nonexistent_pdf
      error = assert_raises(PdfSigner::SigningError) do
        PdfSigner.new("/nonexistent/file.pdf")
      end

      assert_match(/does not exist/, error.message)
    end

    def test_initialization_with_nil_pdf
      error = assert_raises(PdfSigner::SigningError) do
        PdfSigner.new(nil)
      end

      assert_match(/cannot be nil/, error.message)
    end

    def test_initialization_with_invalid_pdf
      invalid_pdf = File.join(@fixtures_path, "invalid.pdf")
      File.write(invalid_pdf, "This is not a PDF")

      error = assert_raises(PdfSigner::SigningError) do
        PdfSigner.new(invalid_pdf)
      end

      assert_match(/Invalid PDF file/, error.message)
    ensure
      FileUtils.rm_f(invalid_pdf) if invalid_pdf
    end

    def test_initialization_with_signature_options
      options = {
        x: 100,
        y: 100,
        width: 200,
        height: 75,
        page: 1,
        reason: "Test signing"
      }

      signer = PdfSigner.new(@pdf_path, options)

      assert_equal 100, signer.signature_options[:x]
      assert_equal 100, signer.signature_options[:y]
      assert_equal 200, signer.signature_options[:width]
      assert_equal 75, signer.signature_options[:height]
      assert_equal 1, signer.signature_options[:page]
      assert_equal "Test signing", signer.signature_options[:reason]
    end

    def test_default_signature_options
      signer = PdfSigner.new(@pdf_path)

      assert_equal 400, signer.signature_options[:x]
      assert_equal 50, signer.signature_options[:y]
      assert_equal 150, signer.signature_options[:width]
      assert_equal 50, signer.signature_options[:height]
      assert_equal "Document approval", signer.signature_options[:reason]
    end

    def test_pdf_info
      signer = PdfSigner.new(@pdf_path)
      info = signer.pdf_info

      assert_equal 2, info[:page_count]
      assert info[:pdf_version]
      assert info[:info]
    end

    def test_sign_success
      signer = PdfSigner.new(@pdf_path)
      signed_path = signer.sign

      assert File.exist?(signed_path)
      assert_match(/_signed\.pdf$/, signed_path)

      # Check that signature metadata was created
      metadata_path = signed_path.sub(/\.pdf$/, "_signature.json")
      assert File.exist?(metadata_path)

      metadata = JSON.parse(File.read(metadata_path))
      assert metadata["signature"]
      assert metadata["certificate"]
      assert metadata["signed_at"]
      assert metadata["signature_options"]
    end

    def test_sign_with_custom_options
      options = {
        x: 50,
        y: 50,
        width: 180,
        height: 60,
        page: 1,
        reason: "Approval",
        location: "Athens, Greece"
      }

      signer = PdfSigner.new(@pdf_path, options)
      signed_path = signer.sign

      metadata_path = signed_path.sub(/\.pdf$/, "_signature.json")
      metadata = JSON.parse(File.read(metadata_path))

      assert_equal 50, metadata["signature_options"]["x"]
      assert_equal 50, metadata["signature_options"]["y"]
      assert_equal "Approval", metadata["signature_options"]["reason"]
      assert_equal "Athens, Greece", metadata["signature_options"]["location"]
    end

    def test_sign_disconnects_provider_on_error
      signer = PdfSigner.new(@pdf_path)

      # Mock the provider to raise an error
      signer.provider.expects(:connect).raises(StandardError, "Connection failed")
      signer.provider.expects(:disconnect).once

      assert_raises(PdfSigner::SigningError) do
        signer.sign
      end
    end

    def test_validate_placement_valid_page
      signer = PdfSigner.new(@pdf_path, { page: 1 })

      assert signer.validate_placement(1)
    end

    def test_validate_placement_invalid_page_too_high
      signer = PdfSigner.new(@pdf_path, { page: 10 })

      error = assert_raises(PdfSigner::SigningError) do
        signer.validate_placement(10)
      end

      assert_match(/Invalid page number/, error.message)
    end

    def test_validate_placement_invalid_page_zero
      signer = PdfSigner.new(@pdf_path, { page: 0 })

      error = assert_raises(PdfSigner::SigningError) do
        signer.validate_placement(0)
      end

      assert_match(/Invalid page number/, error.message)
    end

    def test_validate_placement_with_default_page
      signer = PdfSigner.new(@pdf_path)

      # Should use the page from signature_options
      assert signer.validate_placement
    end

    def test_multiple_signatures
      signer1 = PdfSigner.new(@pdf_path, { reason: "First signature" })
      signed_path1 = signer1.sign

      # Create another signer with the signed PDF
      signer2 = PdfSigner.new(signed_path1, { reason: "Second signature" })
      signed_path2 = signer2.sign

      assert File.exist?(signed_path1)
      assert File.exist?(signed_path2)
      refute_equal signed_path1, signed_path2
    end
  end
end
