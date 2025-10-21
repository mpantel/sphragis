# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial release of Sphragis (Σφραγίς) - Digital PDF Signatures for Rails
- Multi-provider architecture supporting:
  - Fortify WebCrypto (FREE open-source, hardware tokens)
  - Harica (FREE for Greek academic institutions, eIDAS qualified)
  - Itsme (template for free e-signature services)
- Rails Engine with interactive PDF signature placement
- PDF.js-based viewer with drag-and-drop signature positioning
- Provider factory pattern for easy extension
- Configuration system with environment variable support
- Comprehensive documentation suite
- Logo design inspired by ancient Greek σφραγιδόλιθοι (sealstones)
- Complete test suite (Minitest)
- RuboCop code quality checks
- Bundler-audit security scanning

### Documentation
- README.md with quick start guide
- PROVIDERS.md for provider comparison
- FORTIFY_WEBCRYPTO.md for Fortify setup
- LICENSING_SUMMARY.md for cost breakdown
- MULTIPLE_PROVIDERS.md for multi-provider usage
- LOGO.md for branding guidelines
- LOGO_FILES.md for logo assets reference

## Notes

### Breaking Changes Policy
Major version bumps (1.0.0, 2.0.0, etc.) will include breaking changes.
Minor version bumps (0.2.0, 0.3.0, etc.) add features in a backwards-compatible manner.
Patch version bumps (0.1.1, 0.1.2, etc.) are backwards-compatible bug fixes.

### Migration Guides
When breaking changes occur, migration guides will be provided in the changelog entry.

### Free for Greek Academic Institutions
This gem provides **FREE** integration with Harica for Greek academic institutions (.gr.ac domains).
See README.md for details on FREE eIDAS qualified certificates.

---

**Legend**:
- `Added` - New features
- `Changed` - Changes in existing functionality
- `Deprecated` - Soon-to-be removed features
- `Removed` - Removed features
- `Fixed` - Bug fixes
- `Security` - Security fixes and improvements
- `Documentation` - Documentation changes

### Disclaimer

> **⚠️ EARLY DEVELOPMENT VERSION**
>
> This gem is in early development and has not been thoroughly tested in production environments.
> Use at your own risk and test extensively before deploying to production.

**Sphragis is an independent open-source project.** We are NOT affiliated with, endorsed by, or sponsored by Peculiar Ventures (Fortify), Harica, Yubico, Nitrokey, ItsMe, OpenSC Project, or any other third-party service or product mentioned in this project. All trademarks are property of their respective owners.

### Credits

- **[Fortify by Peculiar Ventures](https://github.com/PeculiarVentures/fortify)** - FREE WebCrypto bridge (MIT License)
- **[HARICA](https://www.harica.gr)** - Greek Academic CA (FREE for academic institutions)
- **[Prawn PDF](https://github.com/prawnpdf/prawn)** - Ruby PDF generation (GPL/Commercial)
- **[PDF.js](https://mozilla.github.io/pdf.js/)** - JavaScript PDF rendering (Apache 2.0)
- **[OpenSC](https://github.com/OpenSC/OpenSC)** - PKCS#11 middleware (LGPL)
- Ancient Greek craftsmen who created the original σφραγιδόλιθοι (sealstones)
