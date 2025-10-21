# Fortify WebCrypto Integration (FREE!)

> **⚠️ EARLY DEVELOPMENT VERSION**
>
> This gem is in early development and has not been thoroughly tested in production environments.
> Use at your own risk and test extensively before deploying to production.

## ⚠️ Disclaimer

**Sphragis is an independent open-source project and is NOT affiliated with, endorsed by, or sponsored by:**

- Peculiar Ventures (Fortify developers)
- Yubico (YubiKey manufacturer)
- Nitrokey
- OpenSC Project
- Any hardware token manufacturers or certificate authorities

This documentation explains how to integrate Fortify WebCrypto (a third-party open-source project) with this gem. All product names and trademarks belong to their respective owners. We make no warranties about third-party software or services.

## What is Fortify (Peculiar Ventures)?

**Official**: https://github.com/PeculiarVentures/fortify-releases

Fortify is a **FREE, open-source** application that bridges WebCrypto API to hardware tokens (smart cards, USB tokens, etc.).

### Key Facts
- ✅ **FREE** - MIT License
- ✅ **Open Source**
- ✅ **Cross-platform** (Windows, macOS, Linux)
- ✅ **No licensing costs**
- ✅ Works with any PKCS#11 token

## Installation (All FREE)

### 1. Install Fortify App

#### macOS
```bash
# Option A: Homebrew
brew install fortify

# Option B: Download from GitHub
# https://github.com/PeculiarVentures/fortify-releases/releases
# Download: Fortify-x.x.x.dmg
```

#### Linux
```bash
# Download AppImage from GitHub releases
wget https://github.com/PeculiarVentures/fortify-releases/releases/download/v1.x.x/Fortify-x.x.x.AppImage
chmod +x Fortify-*.AppImage
./Fortify-*.AppImage
```

#### Windows
```powershell
# Download .exe from GitHub releases
# https://github.com/PeculiarVentures/fortify-releases/releases
# Install: Fortify-Setup-x.x.x.exe
```

### 2. Install PKCS#11 Library (FREE)

#### macOS
```bash
# OpenSC - FREE PKCS#11 middleware
brew install opensc
```

#### Linux
```bash
# Debian/Ubuntu
sudo apt-get install opensc

# Fedora/RHEL
sudo dnf install opensc
```

#### Windows
```powershell
# Download OpenSC from: https://github.com/OpenSC/OpenSC/releases
# Install: OpenSC-x.x.x.msi
```

### 3. Get Hardware Token

**Affordable Options:**

| Token | Cost | Features |
|-------|------|----------|
| **YubiKey 5** | ~€50 | Most popular, reliable |
| **Nitrokey Pro** | ~€50 | Open source hardware |
| **Generic PKCS#11** | €20-100 | Various manufacturers |

**Purchase**: Amazon, official websites, security retailers

### 4. Start Fortify

```bash
# Start the Fortify app
fortify

# Or on macOS, just open the app from Applications
# It runs in the background on https://localhost:31337
```

Verify it's running:
```bash
curl -k https://localhost:31337/info
# Should return: {"name":"fortify","version":"..."}
```

## Configure Your Gem

### Update Configuration

```ruby
# config/initializers/sphragis.rb
Sphragis.configure do |config|
  config.default_provider = :fortify_webcrypto

  # Fortify REST API (runs locally)
  config.fortify_url = "https://localhost:31337"

  # Optional: Specific certificate ID
  # config.fortify_certificate_id = "cert_id_from_token"
end
```

## Usage

### 1. Insert Your Token

```bash
# Verify token is detected
pkcs11-tool --module /usr/local/lib/opensc-pkcs11.so --list-slots

# Output:
# Available slots:
# Slot 0 (0x0): Yubico YubiKey OTP+FIDO+CCID
#   token label        : YubiKey PIV
#   token manufacturer : Yubico
```

### 2. Sign PDFs

```ruby
# In your Rails app
signer = Sphragis::PdfSigner.new(pdf_path, {
  provider: :fortify_webcrypto,
  reason: "Invoice approval"
})

signed_path = signer.sign
```

### 3. Interactive UI

Users can select Fortify from the provider dropdown in the web interface.

## Complete Setup Example

### One-Time Setup

```bash
# 1. Install Fortify (FREE)
brew install fortify

# 2. Install OpenSC (FREE)
brew install opensc

# 3. Buy YubiKey (~€50 one-time)
# Purchase from: https://www.yubico.com

# 4. Initialize YubiKey
ykman piv reset  # Reset PIV applet
ykman piv set-pin  # Set PIN (e.g., 123456)

# 5. Generate key and certificate on YubiKey
# Option A: Self-signed (FREE for testing)
ykman piv generate-key --algorithm RSA2048 9a public.pem
ykman piv generate-certificate --subject "CN=My Name" 9a public.pem

# Option B: Use Harica certificate (FREE for academic)
# Get certificate from Harica and import to YubiKey

# 6. Start Fortify
fortify
```

### Rails App Setup

```ruby
# 1. Add gem
gem 'sphragis'

# 2. Configure
# config/initializers/sphragis.rb
Sphragis.configure do |config|
  config.default_provider = :fortify_webcrypto
  config.fortify_url = "https://localhost:31337"
end

# 3. Use it
Invoice.first.generate_and_sign_pdf
```

## Cost Breakdown (Fortify WebCrypto)

| Component | Cost | Frequency | Total |
|-----------|------|-----------|-------|
| **Fortify App** | FREE ✅ | - | €0 |
| **OpenSC Library** | FREE ✅ | - | €0 |
| **YubiKey 5** | €50 | One-time | €50 |
| **Self-signed Cert** | FREE ✅ | - | €0 |
| **OR Harica Cert (Academic)** | FREE ✅ | Annual | €0 |
| **OR Commercial Cert** | €50-200 | Annual | €50-200/year |
| **Your Gem** | FREE ✅ | - | €0 |
| **TOTAL (One-time)** | | | **€50** |
| **TOTAL (Annual)** | | | **€0-200/year** |

**vs. Commercial HSM Solutions: €2,000-5,000/year** 🎉

## Supported Tokens

Fortify works with any PKCS#11 compatible token:

### Tested & Working
- ✅ YubiKey 4/5 (PIV mode)
- ✅ Nitrokey Pro/Storage
- ✅ SafeNet eToken
- ✅ Gemalto (Thales) tokens
- ✅ Smart cards (contact/contactless)
- ✅ SoftHSM (software token for testing)

### Certificate Options

1. **Self-signed (FREE, testing only)**
   ```bash
   ykman piv generate-certificate --subject "CN=Test" 9a public.pem
   ```

2. **Harica (FREE for academic)**
   - Get certificate from Harica
   - Import to token with `ykman piv import-certificate`

3. **Commercial CA (€50-200/year)**
   - Purchase from DigiCert, GlobalSign, etc.
   - Import to token

## Development vs Production

### Development
```ruby
# Use self-signed certificate on YubiKey
config.fortify_url = "https://localhost:31337"
# Cost: €50 (YubiKey) + €0 (self-signed)
```

### Production (Academic)
```ruby
# Use Harica certificate on YubiKey
config.fortify_url = "https://localhost:31337"
config.fortify_certificate_id = "harica_cert_id"
# Cost: €50 (YubiKey) + €0 (Harica academic)
```

### Production (Commercial)
```ruby
# Use commercial certificate on YubiKey
config.fortify_url = "https://localhost:31337"
config.fortify_certificate_id = "commercial_cert_id"
# Cost: €50 (YubiKey) + €200/year (cert)
```

## Advantages Over Cloud Providers

| Feature | Fortify + YubiKey | Cloud E-Signature |
|---------|-------------------|-------------------|
| **Setup Cost** | €50 (one-time) | €0-10/month |
| **Annual Cost** | €0-200 | €120-1200/year |
| **Privacy** | ✅ Local, no cloud | ⚠️ Sent to cloud |
| **Offline** | ✅ Works offline | ❌ Needs internet |
| **Speed** | ✅ Instant | ⚠️ API latency |
| **Security** | ✅ Hardware-backed | ⚠️ Cloud storage |
| **Limits** | ✅ Unlimited | ⚠️ Monthly limits |

## Troubleshooting

### Fortify not running
```bash
# Check if running
curl -k https://localhost:31337/info

# Start it
fortify
```

### Token not detected
```bash
# List PKCS#11 slots
pkcs11-tool --module /usr/local/lib/opensc-pkcs11.so --list-slots

# If empty:
# 1. Check token is inserted
# 2. Check OpenSC is installed
# 3. Restart Fortify
```

### PIN incorrect
```bash
# Reset YubiKey PIN (WARNING: Erases keys!)
ykman piv reset

# Set new PIN
ykman piv set-pin
```

### Certificate not found
```bash
# List certificates on token
pkcs11-tool --module /usr/local/lib/opensc-pkcs11.so --list-objects

# If empty, generate or import certificate
ykman piv generate-certificate --subject "CN=Test" 9a public.pem
```

## Security Best Practices

1. **Keep configuration secure**
   ```ruby
   # Use Rails credentials for sensitive data
   config.fortify_certificate_id = Rails.application.credentials.dig(:fortify, :certificate_id)
   ```

2. **User authentication**
   ```ruby
   # Ensure user is authenticated before allowing signing
   before_action :authenticate_user!
   before_action :authorize_signing!

   def sign_document
     signer = Sphragis::PdfSigner.new(pdf_path, {
       provider: :fortify_webcrypto,
       reason: "Approved by #{current_user.name}"
     })
     signer.sign
   end
   ```

3. **Use hardware-backed certificates**
   - Generate keys ON the token (never export private key)
   - Use YubiKey touch requirement for extra security

4. **Audit logging**
   ```ruby
   after_action :log_signature

   def log_signature
     SignatureAudit.create(
       user: current_user,
       document: @document,
       provider: "fortify_webcrypto",
       certificate: signer.certificate[:subject],
       signed_at: Time.current
     )
   end
   ```

## Summary

### Is Fortify FREE?
✅ **YES!** Fortify (Peculiar Ventures) is completely FREE and open source.

### What do you pay for?
Only the **hardware token** (€50 one-time) and optionally a **certificate** (€0-200/year).

### Total Cost
- **Minimum**: €50 (YubiKey + self-signed cert)
- **Academic**: €50 (YubiKey + FREE Harica cert)
- **Commercial**: €50 + €200/year (YubiKey + commercial cert)

**You're good to go! Install Fortify and start signing for ~€50!** 🚀

## Credits & Acknowledgments

This integration is built on top of excellent open-source software:

- **[Fortify by Peculiar Ventures](https://github.com/PeculiarVentures/fortify)** - FREE WebCrypto bridge (MIT License)
- **[OpenSC](https://github.com/OpenSC/OpenSC)** - FREE PKCS#11 middleware (LGPL)
- **[Yubico](https://www.yubico.com)** - Hardware security tokens
- **[Nitrokey](https://www.nitrokey.com)** - Open-source hardware tokens

Special thanks to Peculiar Ventures for making Fortify free and open-source!
