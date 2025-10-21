# Signature Providers Guide

> **⚠️ EARLY DEVELOPMENT VERSION**
>
> This gem is in early development and has not been thoroughly tested in production environments.
> Use at your own risk and test extensively before deploying to production.


## ⚠️ Disclaimer

**Sphragis is an independent open-source project and is NOT affiliated with, endorsed by, or sponsored by:**

- Peculiar Ventures (Fortify)
- Harica
- Yubico (YubiKey)
- Nitrokey
- ItsMe
- OpenSC Project
- Any certificate authorities or hardware token manufacturers

This documentation provides integration guides for third-party services. All trademarks are property of their respective owners. Users are responsible for complying with each provider's terms of service.

Sphragis supports multiple signature providers, allowing you to choose between hardware tokens, cloud-based e-signature services, and free alternatives.

## Available Providers

### 1. Fortify WebCrypto (Hardware Token)
**Status**: FREE open source software
**Cost**: FREE software + ~€50 hardware token (one-time)
**Security Level**: Highest (Qualified Electronic Signature with proper certificate)

**What is Fortify?**
Fortify by Peculiar Ventures is a FREE, open-source application that provides WebCrypto API access to hardware security tokens (YubiKey, Nitrokey, etc.) via a local REST API.

- **Software**: https://github.com/PeculiarVentures/fortify-releases
- **License**: MIT (completely FREE)
- **Platform**: Windows, macOS, Linux

**Configuration:**
```ruby
Sphragis.configure do |config|
  config.default_provider = :fortify_webcrypto
  config.fortify_url = "https://localhost:31337"
  config.fortify_certificate_id = "certificate_id_from_token"
end
```

**Environment Variables:**
```bash
SIGNATURE_PROVIDER=fortify_webcrypto
FORTIFY_URL=https://localhost:31337
FORTIFY_CERTIFICATE_ID=your_cert_id
```

**What You Need:**
1. **Fortify app** (FREE download from GitHub)
2. **Hardware token** (~€50 one-time cost):
   - YubiKey 5 Series (~€50)
   - Nitrokey Pro 2 (~€50)
   - Any PKCS#11 compatible token
3. **Certificate** (optional, depends on use case):
   - Self-signed: FREE (for testing)
   - Harica: FREE (for Greek academic institutions)
   - Commercial CA: €50-200/year

**Total Cost:**
- **Software**: €0 (FREE)
- **Hardware**: €50 (one-time)
- **Certificate**: €0-200 (depending on needs)

### 2. Harica (Hellenic Academic CA)
**Status**: Available (Free for academic, Paid for commercial)
**Cost**: FREE for Greek academic institutions, paid certificates for commercial use
**Security Level**: Qualified Electronic Signature (eIDAS compliant)

HARICA (Hellenic Academic and Research Institutions CA) is the official CA for Greek academic institutions.

**Configuration:**
```ruby
Sphragis.configure do |config|
  config.default_provider = :harica
  config.harica_api_key = Rails.application.credentials.dig(:harica, :api_key)
  config.harica_certificate_id = "your_certificate_id"
  config.harica_username = "your_username"
  config.harica_password = Rails.application.credentials.dig(:harica, :password)
  config.harica_environment = "production" # or 'sandbox'
end
```

**Environment Variables:**
```bash
SIGNATURE_PROVIDER=harica
HARICA_API_KEY=your_api_key
HARICA_CERTIFICATE_ID=cert_123456
HARICA_USERNAME=your_username
HARICA_PASSWORD=your_password
HARICA_ENVIRONMENT=production
```

**Licensing & Costs:**
- **FREE** for Greek academic institutions (.gr.ac domains)
- **PAID** certificates for commercial organizations (€50-200/year)
- Qualified certificates comply with eIDAS regulation
- Visit: https://www.harica.gr for more information

**Features:**
- CAdES-BES signature format
- EU eIDAS qualified certificates
- Academic identity verification
- REST API integration

### 3. Itsme.free (Template Implementation)
**Status**: Template/Example implementation
**Cost**: Free (template)
**Security Level**: Simple/Advanced Electronic Signature

This is a template implementation showing how to integrate a free e-signature service. Customize based on actual service availability in your region.

**Configuration:**
```ruby
Sphragis.configure do |config|
  config.default_provider = :itsme
  config.itsme_client_id = "your_client_id"
  config.itsme_client_secret = Rails.application.credentials.dig(:itsme, :client_secret)
  config.itsme_user_email = "user@example.com"
  config.itsme_environment = "production" # or 'sandbox'
end
```

**Features:**
- OAuth2 authentication pattern
- PAdES signature format example
- Template for integration
- Simple electronic signature

**Note:** This is a template implementation. Replace with actual free e-signature service available in your region.

## Usage

### Programmatic Signing with Specific Provider

```ruby
# Using Fortify WebCrypto
signer = Sphragis::PdfSigner.new(pdf_path, {
  provider: :fortify_webcrypto,
  reason: "Official document"
})
signed_path = signer.sign

# Using Harica
signer = Sphragis::PdfSigner.new(pdf_path, {
  provider: :harica,
  reason: "Academic approval"
})
signed_path = signer.sign

# Using Itsme template
signer = Sphragis::PdfSigner.new(pdf_path, {
  provider: :itsme,
  reason: "Personal signature"
})
signed_path = signer.sign
```

### Interactive UI

The web interface automatically detects configured providers and allows selection:

```ruby
# In your controller
def sign_document
  @document = Document.find(params[:id])
  redirect_to sphragis.preview_path(
    path: @document.pdf.path,
    provider: :harica # Optional, will use default if omitted
  )
end
```

Users can then select from available providers in the UI.

### Check Available Providers

```ruby
# In your application
Sphragis::ProviderFactory.available_providers
# => [:fortify_webcrypto, :harica] (if configured)

# Check if specific provider is configured
Sphragis.configuration.harica_configured?
# => true/false

# Get provider info
provider = Sphragis::ProviderFactory.create(:harica)
provider.provider_name  # => "Harica"
```

## Free vs Paid Comparison

| Provider | Software Cost | Hardware Cost | Certificate Cost | Security Level | Legal Validity |
|----------|---------------|---------------|------------------|----------------|----------------|
| **Fortify WebCrypto** | FREE | €50 (one-time) | €0-200/year | Qualified* | High (with CA cert) |
| **Harica (Academic)** | FREE | €0 | FREE | Qualified | eIDAS Qualified |
| **Harica (Commercial)** | FREE | €0 | €50-200/year | Qualified | eIDAS Qualified |
| **Itsme (Template)** | FREE | €0 | FREE | Simple | Depends on implementation |

*Qualified level requires certificate from trusted CA (like Harica)

## Choosing a Provider

### For Academic/Research (Greece)
**Recommended: Harica**
- FREE for academic institutions
- Qualified electronic signatures
- eIDAS compliant
- Greek government recognized
- **Total cost: €0**

### For Enterprise/Commercial (Hardware-based)
**Recommended: Fortify WebCrypto + Commercial Certificate**
- FREE software
- €50 hardware (one-time)
- €50-200/year certificate
- Maximum security, hardware-based
- **Total cost: €50-250 first year**

### For Enterprise/Commercial (Cloud-based)
**Recommended: Harica (Paid)**
- FREE software
- No hardware needed
- €50-200/year certificate
- eIDAS qualified
- **Total cost: €50-200/year**

### For Development/Testing
**Recommended: Fortify WebCrypto + Self-signed**
- FREE software
- €50 hardware (one-time)
- FREE self-signed certificate
- Real cryptographic testing
- **Total cost: €50 one-time**

## Creating Custom Providers

You can add your own signature provider by extending `BaseProvider`:

```ruby
module Sphragis
  module Providers
    class MyCustomProvider < BaseProvider
      def connect
        # Implement connection logic
        @session = { connected: true }
      end

      def disconnect
        @session = nil
      end

      def sign(data)
        # Implement signing logic
        {
          provider: "my_custom",
          algorithm: "SHA256withRSA",
          signature: generate_signature(data),
          timestamp: Time.now.utc.iso8601
        }
      end

      def certificate
        # Return certificate info
        {
          provider: "my_custom",
          subject: "CN=My User",
          # ... other certificate details
        }
      end

      private

      def generate_signature(data)
        # Your signing implementation
      end
    end
  end
end
```

Then register it in `ProviderFactory`.

## Security Recommendations

1. **Never hardcode credentials** - Use Rails credentials or environment variables
2. **Use HTTPS** in production for all API calls
3. **Validate certificates** - Verify certificate chain for all providers
4. **Audit logging** - Log all signing operations
5. **Rate limiting** - Implement rate limits for signing endpoints
6. **User authentication** - Require authentication before signing
7. **Authorization** - Verify user permissions for each document
8. **Fortify local-only** - Fortify WebCrypto runs on localhost only (security by design)

## Support & Resources

### Harica
- Website: https://www.harica.gr
- Documentation: https://www.harica.gr/en/support
- Support: support@harica.gr

### Fortify by Peculiar Ventures
- GitHub: https://github.com/PeculiarVentures/fortify-releases
- Documentation: https://github.com/PeculiarVentures/fortify
- Issues: https://github.com/PeculiarVentures/fortify/issues

### This Gem
- GitHub: https://github.com/mpantel/sphragis
- Issues: https://github.com/mpantel/sphragis/issues
- Email: mpantel@aegean.gr

## Compliance

### eIDAS Regulation (EU)
- **Harica**: Fully compliant (Qualified certificates)
- **Fortify WebCrypto**: Depends on certificate used (qualified with CA certificate)
- **Custom providers**: Verify compliance individually

### Greek Law
- **Harica**: Recognized by Greek government
- Suitable for official documents in Greece

### Academic Requirements
- **Harica**: Meets academic institution requirements
- FREE certificates for .gr.ac domains
