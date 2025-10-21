# frozen_string_literal: true

require "test_helper"

module Sphragis
  class DocumentsControllerTest < Minitest::Test
    # Note: This is a basic test setup. Controller testing requires
    # Rails test infrastructure. These tests verify the controller
    # file structure is correct.

    def setup
      super
      @pdf_path = create_test_pdf
    end

    def test_controller_file_exists
      controller_path = File.expand_path("../../../app/controllers/sphragis/documents_controller.rb", __dir__)
      assert File.exist?(controller_path), "Controller file should exist"
    end

    def test_routes_file_exists
      routes_path = File.expand_path("../../../config/routes.rb", __dir__)
      assert File.exist?(routes_path), "Routes file should exist"
    end

    def test_views_directory_exists
      views_path = File.expand_path("../../../app/views/sphragis/documents", __dir__)
      assert File.exist?(views_path), "Views directory should exist"
    end

    def test_preview_view_exists
      preview_view = File.expand_path("../../../app/views/sphragis/documents/preview.html.erb", __dir__)
      assert File.exist?(preview_view), "Preview view should exist"
    end

    def test_javascript_file_exists
      js_file = File.expand_path("../../../app/assets/javascripts/sphragis/application.js", __dir__)
      assert File.exist?(js_file), "JavaScript file should exist"
    end
  end
end
