# frozen_string_literal: true

require "test_helper"

module Sphragis
  class TestConfiguration < Minitest::Test
    def test_default_configuration
      config = Configuration.new

      assert_equal "/usr/lib/fortify/libfortify.so", config.fortify_library_path
      assert_equal 0, config.token_slot
      assert_equal "Signing Certificate", config.certificate_label
    end

    def test_configuration_from_env
      ENV["FORTIFY_LIBRARY_PATH"] = "/custom/path/libfortify.so"
      ENV["FORTIFY_TOKEN_PIN"] = "12345"
      ENV["FORTIFY_TOKEN_SLOT"] = "1"
      ENV["FORTIFY_CERTIFICATE_LABEL"] = "My Certificate"

      config = Configuration.new

      assert_equal "/custom/path/libfortify.so", config.fortify_library_path
      assert_equal "12345", config.token_pin
      assert_equal 1, config.token_slot
      assert_equal "My Certificate", config.certificate_label
    ensure
      ENV.delete("FORTIFY_LIBRARY_PATH")
      ENV.delete("FORTIFY_TOKEN_PIN")
      ENV.delete("FORTIFY_TOKEN_SLOT")
      ENV.delete("FORTIFY_CERTIFICATE_LABEL")
    end

    def test_module_configuration
      Sphragis.configure do |config|
        config.fortify_library_path = "/another/path/libfortify.so"
        config.token_pin = "54321"
        config.token_slot = 2
        config.certificate_label = "Test Certificate"
      end

      config = Sphragis.configuration

      assert_equal "/another/path/libfortify.so", config.fortify_library_path
      assert_equal "54321", config.token_pin
      assert_equal 2, config.token_slot
      assert_equal "Test Certificate", config.certificate_label
    end

    def test_reset_configuration
      Sphragis.configure do |config|
        config.token_pin = "99999"
      end

      assert_equal "99999", Sphragis.configuration.token_pin

      Sphragis.reset_configuration!

      refute_equal "99999", Sphragis.configuration.token_pin
    end
  end
end
