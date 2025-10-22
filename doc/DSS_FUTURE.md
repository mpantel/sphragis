# DSS (Digital Signature Service) - Future Provider

> **📋 STATUS: Research/Planning Phase**
>
> This document describes a potential future integration with EU's Digital Signature Service (DSS).
> This provider is NOT currently implemented in Sphragis.

## What is DSS?

**DSS (Digital Signature Service)** is the European Commission's open-source framework for creating and validating electronic signatures. It's designed for full eIDAS compliance and is used by EU member states for official digital signing services.

- **Developer**: European Commission (Directorate-General for Informatics)
- **License**: LGPL 2.1 (Free & Open Source)
- **Language**: Java
- **Standards**: eIDAS, ETSI (PAdES, XAdES, CAdES, JAdES)
- **Repository**: https://ec.europa.eu/digital-building-blocks/DSS

## Architecture Comparison

### Fortify (Client-Side)
```
┌─────────────┐     HTTPS     ┌─────────────────┐     PKCS#11    ┌──────────────┐
│   Browser   │ ────────────> │ Fortify (local) │ ─────────────> │ Hardware Key │
│             │               │  localhost:31337│               │  (YubiKey)   │
└─────────────┘               └─────────────────┘               └──────────────┘
     User's Machine                                                User owns key
```

### DSS (Server-Side)
```
┌─────────────┐     HTTP      ┌─────────────────┐    PKCS#11     ┌──────────────┐
│ Rails App   │ ────────────> │   DSS Server    │ ─────────────> │  HSM/Token   │
│ (Sphragis)  │               │  (You host)     │               │ (Server-side)│
└─────────────┘               └─────────────────┘               └──────────────┘
     Your Server               Your Infrastructure              Institution owns key
```

### Harica (Cloud Service)
```
┌─────────────┐     HTTPS     ┌─────────────────┐
│ Rails App   │ ────────────> │  Harica Cloud   │
│ (Sphragis)  │               │   (They host)   │
└─────────────┘               └─────────────────┘
     Your Server                  Harica infrastructure
```

## Key Differences

| Aspect | Fortify | DSS | Harica |
|--------|---------|-----|--------|
| **Architecture** | Client-side | Server-side | Cloud SaaS |
| **Who Hosts** | User's PC | You (self-hosted) | Harica |
| **Key Storage** | User's USB token | Your HSM/server | Harica servers |
| **Signing Location** | User's browser | Your server | Harica datacenter |
| **User Interaction** | Per signature | None (automated) | API call |
| **Setup Complexity** | Low | High | Low |
| **Infrastructure Cost** | €50 (hardware) | €500-5000 (HSM) | €0 (academic) |
| **Maintenance** | User manages | You manage | Harica manages |
| **Best For** | Personal signatures | Institutional/batch | Cloud convenience |

## DSS Components

### Core Features
- **Signature Creation**: PAdES (PDF), XAdES (XML), CAdES (binary), JAdES (JSON)
- **Signature Validation**: Multi-level validation with trust chains
- **Certificate Validation**: OCSP, CRL, AIA checking
- **Timestamping**: RFC 3161 timestamp service integration
- **Long-term Validation (LTV)**: Archive signatures for decades

### Modules
1. **dss-spi** - Service Provider Interface
2. **dss-document** - Document handling
3. **dss-token** - PKCS#11, PKCS#12 support
4. **dss-service** - REST API service
5. **dss-standalone-app** - Web UI demo

## When to Use DSS

### ✅ Good Fit:
- **Centralized institutional signing** - University department stamp, official documents
- **Batch processing** - Sign hundreds of diplomas automatically
- **Server-side automation** - Cron jobs, workflow systems
- **Existing HSM infrastructure** - Already have network HSM
- **Compliance requirements** - Need full eIDAS audit trail
- **Multi-format support** - Need XML, JSON signatures too

### ❌ Not a Good Fit:
- **Personal signatures** - Use Fortify (user controls key)
- **Low volume** - Use Harica (simpler setup)
- **No infrastructure budget** - Use Harica (free)
- **PDF-only** - Current providers sufficient
- **Quick prototyping** - Too complex for MVP

## Implementation Requirements

### Infrastructure Needed:

1. **Application Server**
   - Java 11+ (OpenJDK recommended)
   - Tomcat 9+ or similar servlet container
   - 2GB+ RAM
   - Linux server (Ubuntu/Debian recommended)

2. **Hardware Security Module (HSM)**
   - Network HSM (e.g., Thales Luna, Utimaco)
   - OR USB HSM connected to server
   - OR software keystore (less secure, testing only)
   - Cost: €500-5000+ depending on model

3. **Certificates**
   - Qualified certificate from eIDAS-compliant CA
   - Installed on HSM
   - Annual cost: €100-500

4. **Network**
   - Firewall rules for HSM communication
   - HTTPS endpoint for REST API
   - Internal network access from Rails app

### Deployment Steps:

```bash
# 1. Install Java
sudo apt-get install openjdk-11-jdk

# 2. Download DSS
wget https://ec.europa.eu/digital-building-blocks/artifact/.../dss-demo-bundle.zip

# 3. Configure PKCS#11 library
# Edit dss.properties
pkcs11.library=/usr/lib/libpkcs11.so
pkcs11.slot=0
pkcs11.pin=your_hsm_pin

# 4. Deploy WAR to Tomcat
sudo cp dss-demo-bundle.war /var/lib/tomcat9/webapps/

# 5. Configure certificates
# Install qualified certificate on HSM

# 6. Start service
sudo systemctl start tomcat9

# 7. Test API
curl https://your-server/dss-demo-bundle/services/rest/signature/info
```

## Integration with Sphragis

### Proposed Implementation:

```ruby
# config/initializers/sphragis.rb
Sphragis.configure do |config|
  config.default_provider = :dss

  # DSS Configuration
  config.dss_endpoint = "https://dss.aegean.gr:8443/dss"
  config.dss_certificate_id = "university_seal_cert"
  config.dss_auth_token = Rails.application.credentials.dig(:dss, :auth_token)
end

# app/lib/sphragis/providers/dss_provider.rb
module Sphragis
  module Providers
    class DssProvider < BaseProvider
      def sign(document_path, options)
        # 1. Upload document to DSS
        # 2. Request signature with certificate ID
        # 3. Download signed document
        # 4. Return signed PDF path
      end

      def validate_signature(signed_document)
        # Use DSS validation API
      end
    end
  end
end
```

### API Flow:

```
1. Sphragis uploads PDF to DSS REST API
   POST /services/rest/server-signing/sign

2. DSS signs with server-side certificate

3. DSS returns signed PDF

4. Sphragis saves signed document
```

## Cost Comparison

### Greek Academic Institution

#### Current (Harica):
```
Software: FREE
Hardware: €0
Certificate: FREE (.gr.ac)
Maintenance: €0/year
─────────────────────────
Total Year 1: €0
Annual: €0
```

#### With DSS:
```
DSS Software: FREE (open source)
HSM Hardware: €2,000 (one-time)
Certificate: FREE (.gr.ac)
Server: €50/month = €600/year
IT Maintenance: ~€2,000/year
─────────────────────────
Total Year 1: €4,600
Annual: €2,600
```

### ROI Analysis:

DSS makes sense when:
- Signing **> 10,000 documents/year** (automation value)
- Need **institutional seal** (not personal signatures)
- Already have **HSM infrastructure** (marginal cost lower)
- **Compliance requires** server-side signing
- **Batch processing** critical for workflows

## Alternative: Hybrid Approach

Best of both worlds:

```ruby
Sphragis.configure do |config|
  # Personal signatures - User's hardware token
  config.personal_provider = :fortify_webcrypto

  # Institutional seal - Free cloud service
  config.institutional_provider = :harica

  # Future: Batch processing
  # config.batch_provider = :dss
end

# Usage
signer.sign(provider: :personal)      # Student signs with YubiKey
signer.sign(provider: :institutional) # Dean signs with Harica
# signer.sign(provider: :batch)       # System signs 1000 diplomas
```

## References

### Official Resources:
- **DSS Project**: https://ec.europa.eu/digital-building-blocks/DSS
- **GitHub**: https://github.com/esig/dss
- **Documentation**: https://ec.europa.eu/digital-building-blocks/wikis/display/DIGITAL/Documentation
- **Demo Site**: https://ec.europa.eu/digital-building-blocks/DSS/webapp-demo

### Standards:
- **eIDAS Regulation**: EU No 910/2014
- **ETSI TS 102 778**: PAdES (PDF Advanced Electronic Signatures)
- **ETSI TS 101 733**: CAdES
- **ETSI TS 101 903**: XAdES

### HSM Vendors:
- **Thales Luna**: https://cpl.thalesgroup.com/encryption/hardware-security-modules
- **Utimaco**: https://utimaco.com/products/categories/general-purpose-hsms
- **Nitrokey HSM**: https://www.nitrokey.com/products/netHsm (open source, €500-1000)

## Recommendations for Sphragis

### Current Status (v0.1.0):
✅ **Keep existing providers:**
- Fortify (personal signatures)
- Harica (institutional, free for .gr.ac)

### Future Consideration (v0.3.0+):
🔄 **Evaluate DSS if/when:**
1. University needs batch signing (> 10,000/year)
2. Existing HSM infrastructure becomes available
3. Compliance requires on-premise signing
4. Budget allocated for infrastructure

### Recommended Path:
📝 **Document DSS for future reference**
⏳ **Wait for clear institutional need**
💡 **Monitor EU DSS updates and community adoption**

For University of the Aegean's current needs, **Harica + Fortify** provides the best value without infrastructure overhead.

---

**Last Updated**: 2025-10-22
**Status**: Research Phase
**Priority**: Future Enhancement
**Estimated Implementation**: 40-60 hours (full integration + testing)