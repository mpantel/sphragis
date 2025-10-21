# frozen_string_literal: true

require "test_helper"

class TestSphragis < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Sphragis::VERSION
  end

  def test_configuration_is_accessible
    assert_respond_to Sphragis, :configuration
    assert_respond_to Sphragis, :configure
  end

  def test_main_classes_exist
    assert defined?(Sphragis::Configuration)
    assert defined?(Sphragis::HardwareToken)
    assert defined?(Sphragis::PdfSigner)
  end
end
