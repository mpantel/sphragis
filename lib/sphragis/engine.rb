# frozen_string_literal: true

module Sphragis
  class Engine < ::Rails::Engine
    isolate_namespace Sphragis

    config.generators do |g|
      g.test_framework :minitest
      g.fixture_replacement :minitest
    end

    initializer "sphragis.assets" do |app|
      app.config.assets.paths << root.join("app/assets")
      app.config.assets.precompile += %w[sphragis/application.css sphragis/application.js]
    end
  end
end
