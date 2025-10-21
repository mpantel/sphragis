# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "sphragis"

require "minitest/autorun"
require "mocha/minitest"
require "fileutils"

class Minitest::Test
  def setup
    # Reset configuration before each test
    Sphragis.reset_configuration!

    # Create test fixtures directory
    @fixtures_path = File.expand_path("fixtures", __dir__)
    FileUtils.mkdir_p(@fixtures_path)
  end

  def teardown
    # Clean up any test files
    Dir.glob(File.join(@fixtures_path, "*_signed.pdf")).each { |f| FileUtils.rm_f(f) }
    Dir.glob(File.join(@fixtures_path, "*_signature.json")).each { |f| FileUtils.rm_f(f) }
  end

  def create_test_pdf(filename = "test.pdf")
    require "prawn"

    path = File.join(@fixtures_path, filename)
    Prawn::Document.generate(path) do |pdf|
      pdf.text "Test PDF Document"
      pdf.text "This is a test document for signing."
      pdf.start_new_page
      pdf.text "Page 2 content"
    end
    path
  end
end
