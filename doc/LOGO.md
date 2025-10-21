# Sphragis Logo Design

> **⚠️ EARLY DEVELOPMENT VERSION**
>
> This gem is in early development and has not been thoroughly tested in production environments.
> Use at your own risk and test extensively before deploying to production.

## Concept

The logo is inspired by ancient Greek σφραγιδόλιθοι (sphragidolithoi) - sealstones used in Minoan, Mycenaean, and Classical Greek civilizations to seal documents and authenticate their origin. These precious stones were carved with intricate designs and pressed into clay or wax to create official seals.

## Available Logo Files

All logo files are in SVG format (scalable vector graphics) for crisp rendering at any size:

- **`logo.svg`** - Main full-color logo with seal stone design (512×512)
- **`logo-simple.svg`** - Simplified version for small sizes (256×256)
- **`logo-dark.svg`** - Dark mode version with golden Σ (512×512)
- **`logo-horizontal.svg`** - Horizontal layout for headers (800×200)
- **`logo-banner.svg`** - Wide banner for GitHub README (1200×300)
- **`logo-favicon.svg`** - Minimal favicon version (64×64)

## Design Philosophy

Just as ancient seals authenticated documents through physical impression, Sphragis authenticates digital documents through cryptographic signatures. The logo bridges ancient tradition with modern technology.

## Primary Logo Concepts

### Concept 1: Minoan Seal Ring (Recommended)

```
     ╭─────────────╮
    ╱   ≋≋≋ Σ ≋≋≋   ╲
   │  ┌───────────┐  │
   │  │  SPHRAGIS │  │
   │  └───────────┘  │
    ╲               ╱
     ╰─────────────╯
```

**Description:**
- Oval shape reminiscent of Minoan seal rings
- Greek letter Σ (Sigma) at center - first letter of Σφραγίς
- Wavy lines (≋) representing ancient seal impressions in wax
- Clean, professional appearance suitable for documentation

### Concept 2: Circular Seal Impression

```
        ╭───────╮
      ╱           ╲
     │   ┌─────┐   │
    │    │  Σ  │    │
    │    │ ─── │    │
    │    └─────┘    │
     │  SPHRAGIS   │
      ╲           ╱
        ╰───────╯
```

**Description:**
- Circular seal impression common in Classical Greek period
- Central Σ within a frame
- Name along the bottom edge
- Evokes official authentication stamps

### Concept 3: Lentoid Seal Stone

```
    ┌─────────────┐
   ╱   ════════   ╲
  │      ╔═╗       │
  │      ║Σ║       │
  │      ╚═╝       │
   ╲   SPHRAGIS  ╱
    └─────────────┘
```

**Description:**
- Lentoid (lens-shaped) seal design
- Framed Σ representing the carved surface
- Horizontal lines suggest layers of seal impression
- Bold, distinctive shape

### Concept 4: Minimalist Modern

```
   ┌───┐
   │ Σ │  SPHRAGIS
   └───┘  Digital PDF Signatures
```

**Description:**
- Clean, modern interpretation
- Single Greek letter in box
- Suitable for documentation headers
- Professional and understated

## Color Palette

Inspired by ancient Greek art and Mediterranean heritage:

### Primary Colors
- **Deep Aegean Blue** (#0B3D91) - Trust, security, Mediterranean sea
- **Ancient Gold** (#D4AF37) - Precious metals used in seal rings
- **Marble White** (#F8F8FF) - Greek marble, purity

### Secondary Colors
- **Terracotta** (#E2725B) - Clay seals, warmth
- **Olive Green** (#6B8E23) - Greek olive trees, growth
- **Charcoal** (#36454F) - Stone carving, stability

## Typography & Font Credits

### Font Used in All Logo Files

**Georgia** - System serif font (free with all operating systems)
- **License**: Proprietary (Microsoft), but freely bundled with Windows, macOS, and Linux
- **Designer**: Matthew Carter (1993)
- **Why Georgia**:
  - Pre-installed on virtually all systems (Windows, macOS, Linux)
  - Excellent Greek character support (Σφραγίς rendered beautifully)
  - Classic, authoritative serif design perfect for legal/official documents
  - No licensing concerns - available on all target platforms
  - Part of Microsoft's Core Fonts for the Web initiative

### Fallback Fonts
All logo SVG files specify fallback fonts for maximum compatibility:
```
font-family="Georgia, 'Times New Roman', serif"
```

This ensures the logo renders correctly even if Georgia is unavailable (extremely rare).

### Typography Recommendations for Documentation

#### Primary Font
- **Serif font** for headings - traditional, authoritative
- Suggested free fonts:
  - **Cormorant** (SIL Open Font License) - Google Fonts
  - **Crimson Text** (SIL Open Font License) - Google Fonts
  - **Libre Baskerville** (SIL Open Font License) - Google Fonts

#### Secondary Font
- **Sans-serif** for technical documentation
- Suggested free fonts:
  - **Inter** (SIL Open Font License) - Google Fonts
  - **Source Sans Pro** (SIL Open Font License) - Adobe/Google Fonts
  - **Roboto** (Apache License 2.0) - Google Fonts

## Usage Guidelines

### Full Logo
Use for:
- Gem documentation homepage
- RubyGems.org listing
- GitHub repository banner
- README header

### Icon Only (Σ in frame)
Use for:
- Favicon
- App icons
- Small-scale usage
- Loading indicators

### Text Only
Use for:
- Code comments
- CLI output
- Inline documentation

## SVG Logo Concept

For a professional implementation, the logo should be created as SVG with the following elements:

1. **Outer oval/circle** - representing the seal stone shape
2. **Inner border** - decorative Greek key pattern (meander)
3. **Central Σ** - bold, serif Greek letter
4. **Text "SPHRAGIS"** - below or around the circular edge
5. **Subtle texture** - suggesting stone/seal impression

## Historical References

### Minoan Sealstones (2000-1450 BCE)
- Lentoid and amygdaloid shapes
- Carved with animals, religious symbols, Linear A script
- Made from agate, carnelian, jasper

### Mycenaean Seals (1600-1100 BCE)
- Gold signet rings
- Elaborate scenes of ritual and warfare
- Impressed into clay for official documents

### Classical Greek Seals (500-300 BCE)
- Scarab and scaraboid shapes
- Profile portraits, gods, athletes
- Used for commercial and legal authentication

## Ancient Σφραγίς Reference

The word Σφραγίς (sphragis) appears in ancient Greek literature:
- Homer uses it for seals on letters
- Herodotus mentions royal seals
- Biblical Greek uses it for authentication

The logo honors this 3,000-year tradition of document authentication.

## Usage Guidelines

### In README.md

```markdown
# ![Sphragis](logo-simple.svg) Sphragis

Or for the banner version:

![Sphragis Banner](logo-banner.svg)
```

### In HTML Documentation

```html
<!-- Main logo -->
<img src="logo.svg" alt="Sphragis Logo" width="200">

<!-- Dark mode support -->
<picture>
  <source srcset="logo-dark.svg" media="(prefers-color-scheme: dark)">
  <img src="logo.svg" alt="Sphragis Logo" width="200">
</picture>

<!-- Horizontal layout -->
<img src="logo-horizontal.svg" alt="Sphragis" width="400">

<!-- Favicon -->
<link rel="icon" type="image/svg+xml" href="logo-favicon.svg">
```

### In Rails Engine

For gem integration:
- Store logo files in `app/assets/images/sphragis/`
- Reference in views: `<%= image_tag 'sphragis/logo.svg', alt: 'Sphragis' %>`
- Include dark mode variants
- All files are SVG for perfect scaling

## ASCII Art for CLI

For terminal output:

```
   ╔═══════════════════════════════════╗
   ║                                   ║
   ║   ┌─────┐                         ║
   ║   │  Σ  │   S P H R A G I S      ║
   ║   └─────┘                         ║
   ║                                   ║
   ║   Σφραγίς - Digital PDF Seals    ║
   ║                                   ║
   ╚═══════════════════════════════════╝
```

## Emoji Representation

For quick reference in documentation:
- 🔏 (closed lock with key) - security
- 📜 (scroll) - documents
- ✍️ (writing hand) - signing
- 🏛️ (classical building) - Greek heritage

Recommended: **🔏 Sphragis** or **📜 Σφραγίς**

---

*Logo design inspired by ancient Greek σφραγιδόλιθοι (sealstones) from the Minoan, Mycenaean, and Classical periods. These precious carved stones authenticated documents for over 3,000 years - now Sphragis continues this tradition in the digital age.*
