# frozen_string_literal: true

require_relative "lib/sphragis/version"

Gem::Specification.new do |spec|
  spec.name = "sphragis"
  spec.version = Sphragis::VERSION
  spec.authors = ["Michail Pantelelis"]
  spec.email = ["mpantel@aegean.gr"]

  spec.summary = "Σφραγίς - Digital signatures for PDFs with multiple providers"
  spec.description = "Sphragis (Σφραγίς - Greek for 'seal') provides multi-provider PDF digital signatures. Supports hardware tokens (Fortify WebCrypto), cloud e-signatures (Harica), and more. Perfect for academic institutions and commercial use. Rails 6.1+ compatible."
  spec.homepage = "https://github.com/mpantel/sphragis"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/mpantel/sphragis"
  spec.metadata["changelog_uri"] = "https://github.com/mpantel/sphragis/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore test/])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "prawn", "~> 2.4"
  spec.add_dependency "rails", ">= 6.1", "< 9.0"
  spec.add_dependency "pdf-reader", "~> 2.0"

  # Development dependencies
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "mocha", "~> 2.0"
  spec.add_development_dependency "rails-controller-testing", "~> 1.0"
  spec.add_development_dependency "rubocop", "~> 1.50"
  spec.add_development_dependency "rubocop-rails", "~> 2.19"
  spec.add_development_dependency "rubocop-minitest", "~> 0.31"
  spec.add_development_dependency "bundler-audit", "~> 0.9"
  spec.add_development_dependency "brakeman", "~> 6.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
