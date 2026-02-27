# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Sphragis is a Ruby gem (Rails Engine) providing multi-provider PDF digital signatures. It targets Greek academic institutions (free via Harica) and commercial use (Fortify hardware tokens). Early development — provider integrations currently use simulated/placeholder implementations.

## Commands

```bash
bundle exec rake test          # Run full test suite (Minitest)
bundle exec ruby -Ilib:test test/sphragis/test_pdf_signer.rb  # Run single test file
bundle exec rubocop            # Lint
bundle exec bundle-audit check # Security audit
bundle exec rake build         # Build gem
```

## Architecture

**Rails Engine** (`Sphragis::Engine`) mounted at a user-chosen path (e.g., `/signatures`). Isolates namespace.

**Provider pattern** — all signing goes through `Providers::BaseProvider` (abstract):
- `FortifyProvider` — PKCS#11 hardware token signing (simulated)
- `FortifyWebcryptoProvider` — Fortify WebCrypto bridge REST API (simulated, most complete API sketch)
- `HaricaProvider` — Harica cloud CA REST API (simulated)
- `ItsmeProvider` — template/example provider (simulated)

Providers are lazily `require_relative`'d by `ProviderFactory.create(:name)`. The factory reads global config to build provider instances.

**Key flow**: `PdfSigner.new(path, opts)` → `ProviderFactory.create` → `provider.connect` → `provider.sign(data)` → writes `_signed.pdf` + `_signature.json` sidecar.

**Configuration**: `Sphragis.configure { |c| ... }` block populating `Sphragis::Configuration`. Defaults from ENV vars. Reset with `Sphragis.reset_configuration!` (used in test setup).

**Controller**: `DocumentsController` handles preview/view/sign/validate_placement. Preview renders PDF.js UI for drag-and-drop signature placement.

## Conventions

- `frozen_string_literal: true` on all Ruby files
- RuboCop with `rubocop-rails` and `rubocop-minitest` plugins
- Double-quoted strings (`Style/StringLiterals: double_quotes`)
- Max line length 120, method length 25, class length 150, AbcSize 20
- Tests use Minitest + Mocha for mocking; test helper resets config and creates temp PDFs via Prawn
- Ruby >= 3.2, Rails >= 6.1 < 8.0

## Test Setup

Tests auto-reset `Sphragis.configuration` in `setup`. `create_test_pdf` generates a 2-page PDF in `test/fixtures/`. Teardown cleans `*_signed.pdf` and `*_signature.json` artifacts.

Most provider tests configure Fortify credentials since it's the default provider. To test other providers, configure the appropriate credentials and pass `provider: :harica` (etc.) in options.
