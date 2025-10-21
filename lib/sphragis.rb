# frozen_string_literal: true

require_relative "sphragis/version"
require_relative "sphragis/configuration"
require_relative "sphragis/hardware_token"
require_relative "sphragis/providers/base_provider"
require_relative "sphragis/provider_factory"
require_relative "sphragis/pdf_signer"
require_relative "sphragis/engine" if defined?(Rails)

module Sphragis
  class Error < StandardError; end
end
