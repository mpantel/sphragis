# Complete Licensing Summary

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

This gem provides integration code to work with these third-party services and products. All trademarks, product names, and company names mentioned in this documentation are the property of their respective owners.

**Use of third-party services:**
- You are responsible for complying with each provider's terms of service
- You are responsible for any costs associated with third-party services
- We make no warranties about the availability or functionality of third-party services
- This documentation is provided for informational purposes only

## Quick Answer

**Can you integrate for FREE?**
### ✅ YES! Multiple FREE options:

| Provider | Software Cost | Hardware Cost | Certificate Cost | Total First Year |
|----------|---------------|---------------|------------------|------------------|
| **Harica (Academic)** | FREE ✅ | €0 | FREE ✅ | **€0** 🎉 |
| **Fortify WebCrypto + YubiKey (Self-signed)** | FREE ✅ | €50 | FREE ✅ | **€50** |
| **Fortify WebCrypto + YubiKey + Harica** | FREE ✅ | €50 | FREE ✅ | **€50** |
| **Simulated (Dev)** | FREE ✅ | €0 | FREE ✅ | **€0** |

## Provider Breakdown

### 1. Harica (Cloud E-Signature)

**Software**: https://www.harica.gr
**License**: FREE for Greek academic institutions

#### Cost
- ✅ **Academic use**: €0/year
- ⚠️ **Commercial use**: €50-200/year

#### What You Need
- Email at Greek academic institution (`@aegean.gr` ✅)
- Register at harica.gr
- API credentials (provided after registration)

#### Total Cost (Academic)
```
Software: FREE
Hardware: Not needed
Certificate: FREE
Annual: €0
```

### 2. Fortify WebCrypto by Peculiar Ventures (Hardware Tokens)

**Software**: https://github.com/PeculiarVentures/fortify-releases
**License**: MIT (FREE, Open Source)

**What is Fortify?**
Fortify is a FREE, open-source desktop application that provides WebCrypto API access to hardware security tokens (YubiKey, Nitrokey, etc.) through a local REST API on port 31337.

#### Cost
- ✅ **Fortify app**: FREE (MIT license)
- ✅ **OpenSC library**: FREE (LGPL)
- ⚠️ **Hardware token**: €20-100 (one-time)
- ⚠️ **Certificate**: €0-200/year (optional)

#### What You Need
1. **Fortify app** (FREE download from GitHub)
2. **OpenSC** (FREE - PKCS#11 library)
3. **Hardware token** (€20-100 one-time purchase)
   - YubiKey 5: ~€50
   - Nitrokey Pro 2: ~€50
   - Generic PKCS#11 tokens: €20-100
4. **Certificate** (choose one):
   - Self-signed: FREE (testing only)
   - Harica: FREE (if academic)
   - Commercial CA: €50-200/year

#### Total Cost Options

**Option A: Testing/Development**
```
Fortify app: FREE
OpenSC: FREE
YubiKey: €50 (one-time)
Self-signed cert: FREE
Total: €50 (one-time)
Annual: €0
```

**Option B: Academic Production**
```
Fortify app: FREE
OpenSC: FREE
YubiKey: €50 (one-time)
Harica cert: FREE (academic)
Total: €50 (one-time)
Annual: €0
```

**Option C: Commercial Production**
```
Fortify app: FREE
OpenSC: FREE
YubiKey: €50 (one-time)
Commercial cert: €200
Total: €250 (first year)
Annual: €200/year
```

### 3. Itsme/Simulated (Development)

**Software**: Built into gem
**License**: Part of your gem (FREE)

#### Cost
- ✅ **Everything**: FREE

#### What You Need
- Nothing! Works immediately
- Signatures are simulated (not legally valid)

#### Total Cost
```
Total: €0
Annual: €0
```

## Fortify WebCrypto Explained

### Common Confusion
There are many products with "Fortify" in the name. This gem integrates with:

**Fortify by Peculiar Ventures**
- ✅ FREE open-source software (MIT license)
- ✅ GitHub: https://github.com/PeculiarVentures/fortify-releases
- ✅ Provides WebCrypto API for hardware tokens
- ✅ Runs locally on your computer (port 31337)
- ✅ No cloud services, no subscriptions, no licensing fees

**NOT related to:**
- ❌ Micro Focus Fortify (commercial security testing)
- ❌ Any commercial HSM products
- ❌ Any subscription-based services

## Your Gem Licensing

### The Gem Itself
```
License: MIT (or your choice)
Cost to users: FREE
Distribution: FREE
Commercial use: FREE
```

### Dependencies (All FREE)
- Rails: FREE ✅
- Prawn: FREE ✅
- PDF.js: FREE ✅
- Ruby: FREE ✅

### Provider Integrations

**Included in Gem (FREE):**
- ✅ Harica provider implementation
- ✅ Fortify WebCrypto provider implementation
- ✅ Simulated provider implementation
- ✅ Provider abstraction layer

**Users Must Provide:**
- For Harica: Registration (FREE for academic)
- For Fortify WebCrypto: Hardware token (€20-100 one-time)
- For Simulated: Nothing!

## Recommended Setup by Use Case

### Greek University/Academic
```ruby
# Use Harica - Completely FREE
config.default_provider = :harica
config.harica_username = "you@aegean.gr"
# Cost: €0
```

### Development/Testing
```ruby
# Option A: Simulated (instant, no setup)
config.default_provider = :itsme
# Cost: €0

# Option B: Real hardware (€50)
config.default_provider = :fortify_webcrypto
# Buy YubiKey, use self-signed cert
# Cost: €50 one-time
```

### Commercial Production
```ruby
# Option A: Fortify WebCrypto + Commercial Cert
config.default_provider = :fortify_webcrypto
# YubiKey + commercial certificate
# Cost: €50 + €200/year = €250 first year

# Option B: Harica Commercial
config.default_provider = :harica
# Commercial Harica certificate
# Cost: €50-200/year
```

## License Comparison Chart

| Component | License | Cost | Source |
|-----------|---------|------|--------|
| **Sphragis (Your Gem)** | MIT (your choice) | FREE | Open source |
| **Harica API** | Terms of Service | FREE (academic) | Cloud service |
| **Fortify WebCrypto** | MIT | FREE | https://github.com/PeculiarVentures/fortify-releases |
| **OpenSC** | LGPL | FREE | https://github.com/OpenSC/OpenSC |
| **Rails** | MIT | FREE | Open source |
| **Prawn** | GPL/Commercial | FREE (GPL) | Open source |
| **YubiKey** | Hardware | €50 | Purchase |

## Legal Considerations

### Can You Distribute Your Gem?
✅ **YES** - Your gem is FREE and open source

### Can Users Use It Commercially?
✅ **YES** - All software components are free for commercial use

### What About Fortify WebCrypto?
✅ **FREE** - MIT license allows commercial use, no restrictions

### What About Harica?
- ✅ **Academic**: FREE to use
- ⚠️ **Commercial**: Requires paid certificate (€50-200/year)

### What Licenses Must Users Agree To?
1. **Sphragis gem**: MIT (permissive)
2. **Fortify WebCrypto**: MIT (permissive)
3. **OpenSC**: LGPL (permissive for use)
4. **Harica**: Terms of Service (if using Harica)

No proprietary licenses required! ✅

## Summary Table

### Total Cost of Ownership (3 Years)

| Setup | Year 1 | Year 2 | Year 3 | 3-Year Total |
|-------|--------|--------|--------|--------------|
| **Harica (Academic)** | €0 | €0 | €0 | **€0** |
| **Fortify WebCrypto + Self-signed** | €50 | €0 | €0 | **€50** |
| **Fortify WebCrypto + Harica** | €50 | €0 | €0 | **€50** |
| **Fortify WebCrypto + Commercial** | €250 | €200 | €200 | **€650** |
| **Simulated (Dev)** | €0 | €0 | €0 | **€0** |

## Final Answer

### Can you integrate Fortify WebCrypto for free?

✅ **YES!**

**Fortify WebCrypto by Peculiar Ventures is:**
- FREE software (MIT license)
- Open source
- No licensing fees
- Free for commercial use
- No subscriptions or recurring costs

**You only pay for:**
- Hardware token: ~€50 (one-time)
- Optional certificate: €0-200/year (depending on use case)

**Total: €50-250 (all software is FREE)**

### Best Setup for You

**If you're at University of the Aegean:**
1. Use **Harica** for cloud signing (€0)
2. OR buy **YubiKey** + use **Fortify WebCrypto** (€50 one-time)
3. OR use **both** (let users choose)

**All software is completely FREE!** 🚀

## Additional Resources

### Fortify WebCrypto Documentation
- Main repo: https://github.com/PeculiarVentures/fortify
- Releases: https://github.com/PeculiarVentures/fortify-releases
- Issues: https://github.com/PeculiarVentures/fortify/issues

### Hardware Token Resources
- YubiKey: https://www.yubico.com
- Nitrokey: https://www.nitrokey.com
- OpenSC: https://github.com/OpenSC/OpenSC

### Certificate Authorities
- Harica: https://www.harica.gr
- Let's Encrypt: https://letsencrypt.org (for TLS, not code signing)
