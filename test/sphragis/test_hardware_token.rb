# frozen_string_literal: true

require "test_helper"

module Sphragis
  class TestHardwareToken < Minitest::Test
    def setup
      super
      Sphragis.configure do |config|
        config.fortify_library_path = "/usr/lib/fortify/libfortify.so"
        config.token_pin = "123456"
        config.token_slot = 0
        config.certificate_label = "Test Certificate"
      end

      @token = HardwareToken.new
    end

    def test_initialization
      assert_instance_of HardwareToken, @token
      assert_instance_of Configuration, @token.config
      refute @token.connected?
    end

    def test_connect_success
      assert @token.connect
      assert @token.connected?
    end

    def test_connect_without_library_path
      Sphragis.configure do |config|
        config.fortify_library_path = nil
      end

      token = HardwareToken.new
      error = assert_raises(HardwareToken::TokenError) do
        token.connect
      end

      assert_match(/Fortify library path not configured/, error.message)
    end

    def test_connect_without_pin
      Sphragis.configure do |config|
        config.token_pin = nil
      end

      token = HardwareToken.new
      error = assert_raises(HardwareToken::TokenError) do
        token.connect
      end

      assert_match(/Token PIN not configured/, error.message)
    end

    def test_disconnect
      @token.connect
      assert @token.connected?

      @token.disconnect
      refute @token.connected?
    end

    def test_sign_when_not_connected
      error = assert_raises(HardwareToken::TokenError) do
        @token.sign("test data")
      end

      assert_match(/Not connected to token/, error.message)
    end

    def test_sign_success
      @token.connect

      result = @token.sign("test data to sign")

      assert result.is_a?(Hash)
      assert_equal "SHA256withRSA", result[:algorithm]
      assert result[:signature]
      assert result[:timestamp]
    end

    def test_sign_different_data_produces_different_signatures
      @token.connect

      signature1 = @token.sign("data 1")
      signature2 = @token.sign("data 2")

      refute_equal signature1[:signature], signature2[:signature]
    end

    def test_certificate_when_not_connected
      error = assert_raises(HardwareToken::TokenError) do
        @token.certificate
      end

      assert_match(/Not connected to token/, error.message)
    end

    def test_certificate_success
      @token.connect

      cert = @token.certificate

      assert cert.is_a?(Hash)
      assert_match(/Test Certificate/, cert[:subject])
      assert cert[:issuer]
      assert cert[:serial]
      assert cert[:not_before]
      assert cert[:not_after]
    end

    def test_certificate_validity_dates
      @token.connect

      cert = @token.certificate

      assert cert[:not_before] < Time.now
      assert cert[:not_after] > Time.now
    end
  end
end
