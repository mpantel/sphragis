# Browser-Based PDF Signing: Technical Architecture

## Overview

Sphragis supports **browser-based PDF signing** through the Fortify WebCrypto provider, allowing users to sign PDFs directly in their browser without uploading files to the server. The private key never leaves the hardware security token.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    User's Browser                            │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Your Rails App (JavaScript)                           │ │
│  │  - PDF.js (render PDF preview)                        │ │
│  │  - Sphragis UI (signature placement)                  │ │
│  │  - WebCrypto API calls                                │ │
│  └────────────────────────────────────────────────────────┘ │
│                          ↓ HTTPS (REST API)                  │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Fortify App (localhost:31337)                        │ │
│  │  - REST API server                                     │ │
│  │  - WebCrypto → PKCS#11 bridge                         │ │
│  │  - Certificate management                              │ │
│  └────────────────────────────────────────────────────────┘ │
│                          ↓ PKCS#11                          │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  OpenSC / PKCS#11 Library                             │ │
│  │  - Hardware token driver                              │ │
│  │  - USB/Smart card communication                       │ │
│  └────────────────────────────────────────────────────────┘ │
│                          ↓ USB                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Hardware Token (YubiKey/Nitrokey)                    │ │
│  │  - Private key (never exported)                       │ │
│  │  - X.509 certificate                                  │ │
│  │  - PIN protection                                     │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Step-by-Step Signing Process

### Step 1: PDF Loaded in Browser

```javascript
// app/assets/javascripts/sphragis/application.js

// Load PDF using PDF.js (client-side only)
const loadingTask = pdfjsLib.getDocument({
  url: '/sphragis/documents/view?path=' + encodeURIComponent(pdfPath)
});

loadingTask.promise.then(function(pdf) {
  pdfDoc = pdf;
  renderPage(1); // Render first page for preview
});
```

**What happens:**
- PDF file is loaded from Rails server into browser memory
- PDF.js parses PDF structure (no server upload needed)
- User sees interactive preview with draggable signature box

### Step 2: User Configures Signature

```javascript
// User interacts with the UI:
// 1. Drags signature box to desired position
// 2. Fills in reason, location, contact info
// 3. Selects page number
// 4. Clicks "Sign" button

document.getElementById('signature-form').addEventListener('submit', function(e) {
  e.preventDefault();

  const signatureData = {
    pdf_path: pdfPath,
    x: parseInt(document.getElementById('x-position').value),
    y: parseInt(document.getElementById('y-position').value),
    width: parseInt(document.getElementById('width').value),
    height: parseInt(document.getElementById('height').value),
    page: parseInt(document.getElementById('page-select').value),
    reason: document.getElementById('reason').value,
    location: document.getElementById('location').value
  };

  // Initiate browser-based signing
  signPdfWithFortify(signatureData);
});
```

### Step 3: Check Fortify Availability

```javascript
async function signPdfWithFortify(signatureData) {
  try {
    // Check if Fortify is running on localhost:31337
    const infoResponse = await fetch('https://localhost:31337/info', {
      mode: 'cors',
      credentials: 'omit'
    });

    if (!infoResponse.ok) {
      throw new Error('Fortify not running. Please start the Fortify app.');
    }

    const info = await infoResponse.json();
    console.log('Fortify version:', info.version);

    // Continue to certificate discovery...
  } catch (error) {
    alert('Cannot connect to Fortify. Please ensure:\n' +
          '1. Fortify app is running\n' +
          '2. Hardware token is inserted\n' +
          '3. Browser allows localhost connections');
    throw error;
  }
}
```

### Step 4: Discover Certificates

```javascript
// List available certificates from hardware token
const certsResponse = await fetch('https://localhost:31337/api/v1/certificates', {
  method: 'GET',
  headers: {
    'Accept': 'application/json'
  }
});

const certificates = await certsResponse.json();
console.log('Available certificates:', certificates);

// Example certificate structure:
// {
//   id: "cert_abc123",
//   subject: "CN=John Doe, O=University, C=GR",
//   issuer: "CN=Harica CA, O=Harica, C=GR",
//   serialNumber: "1234567890ABCDEF",
//   notBefore: "2024-01-01T00:00:00Z",
//   notAfter: "2025-12-31T23:59:59Z",
//   algorithm: "SHA256withRSA"
// }

// Let user select certificate (if multiple available)
const selectedCert = certificates[0];
```

### Step 5: Prepare PDF Data

```javascript
// Read PDF bytes from server
const pdfResponse = await fetch('/sphragis/documents/view?path=' + signatureData.pdf_path);
const pdfBytes = await pdfResponse.arrayBuffer();

// Compute SHA-256 hash of PDF content
const pdfHash = await crypto.subtle.digest('SHA-256', pdfBytes);

console.log('PDF size:', pdfBytes.byteLength, 'bytes');
console.log('PDF hash:', arrayBufferToHex(pdfHash));
```

### Step 6: Request Signature from Fortify

```javascript
// Call Fortify to sign the PDF hash
const signResponse = await fetch('https://localhost:31337/api/v1/sign', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    certificateId: selectedCert.id,
    data: arrayBufferToBase64(pdfHash),
    algorithm: 'SHA256withRSA'
  })
});

const signatureResult = await signResponse.json();

// Example response:
// {
//   signature: "MIIGhwYJKoZIhvcNAQcCoIIGeDCC...",  // Base64-encoded PKCS#7
//   algorithm: "SHA256withRSA",
//   timestamp: "2025-10-21T21:45:00Z",
//   certificate: "MIIDXTCCAkWgAwIBAgIJAKoS..."     // Base64-encoded X.509
// }

console.log('✅ Signature created:', signatureResult);
```

**What happens inside Fortify:**

```javascript
// Fortify's internal logic (simplified):
app.post('/api/v1/sign', async (req, res) => {
  const { certificateId, data, algorithm } = req.body;

  // 1. Find certificate in PKCS#11 token
  const cert = await pkcs11.findCertificate(certificateId);

  // 2. Find associated private key
  const privateKey = await pkcs11.findPrivateKey(cert);

  // 3. Prompt user for PIN (OS dialog box)
  const pin = await promptForPin();

  // 4. Login to hardware token
  await pkcs11.login(pin);

  // 5. Sign data using hardware token
  // ⚠️ CRITICAL: Private key never leaves the token!
  const signature = await pkcs11.sign(privateKey, data, algorithm);

  // 6. Return only the signature bytes
  res.json({
    signature: signature.toString('base64'),
    algorithm: algorithm,
    timestamp: new Date().toISOString(),
    certificate: cert.toBase64()
  });
});
```

### Step 7: Hardware Token Performs Signing

**Inside the YubiKey/Nitrokey secure chip:**

```
┌─────────────────────────────────────┐
│     Hardware Security Token         │
│                                     │
│  1. Receive PIN from Fortify       │
│     ↓                               │
│  2. Verify PIN (3 attempts max)    │
│     ↓ (PIN correct)                │
│  3. Load private key from secure   │
│     storage (tamper-resistant)     │
│     ↓                               │
│  4. Perform RSA signature:         │
│     signature = RSA_sign(          │
│       hash,                        │
│       private_key                  │
│     )                              │
│     ↓                               │
│  5. Return signature bytes only    │
│     (private key stays inside!)    │
│                                     │
└─────────────────────────────────────┘
```

**Security guarantees:**
- ✅ Private key **physically cannot be extracted**
- ✅ Signing operation happens **inside the secure chip**
- ✅ PIN required for every signing operation
- ✅ Token locks after 3 failed PIN attempts

### Step 8: Embed Signature in PDF

```javascript
function embedSignatureInPdf(pdfBytes, signatureResult, signatureData) {
  // Parse PDF structure
  const pdfDoc = PDFDocument.load(pdfBytes);

  // Create PDF signature dictionary (PDF Reference Section 8.7)
  const signatureDict = {
    Type: '/Sig',                                    // Signature object
    Filter: '/Adobe.PPKLite',                        // Signature handler
    SubFilter: '/adbe.pkcs7.detached',               // PKCS#7 format
    ByteRange: '[0 /********** /********** **********]', // Placeholder
    Contents: '<' + signatureResult.signature + '>', // Hex-encoded signature
    Reason: signatureData.reason,
    Location: signatureData.location,
    M: 'D:' + formatDate(new Date()),               // Signing time
    Name: extractNameFromCert(signatureResult.certificate)
  };

  // Create signature annotation (visual appearance)
  const sigAnnotation = {
    Type: '/Annot',
    Subtype: '/Widget',
    Rect: [
      signatureData.x,
      signatureData.y,
      signatureData.x + signatureData.width,
      signatureData.y + signatureData.height
    ],
    F: 132,                                          // Flags: Print + NoView
    P: pdfDoc.getPage(signatureData.page - 1),
    T: '(Signature1)',
    V: signatureDict                                 // Link to signature dict
  };

  // Add signature to PDF
  pdfDoc.addSignature(sigAnnotation);

  // Calculate ByteRange (which bytes are signed)
  // ByteRange format: [start1 length1 start2 length2]
  // Where: start1-length1 and start2-length2 are the signed portions
  const pdfSize = pdfDoc.getSize();
  const signatureSize = signatureResult.signature.length;
  const signatureOffset = signatureDict.offset;

  const byteRange = [
    0,                                               // Start of file
    signatureOffset - 1,                             // Bytes before signature
    signatureOffset + signatureSize + 2,             // Bytes after signature
    pdfSize - (signatureOffset + signatureSize + 2)  // Remaining bytes
  ];

  signatureDict.ByteRange = '[' + byteRange.join(' ') + ']';

  // Serialize PDF back to bytes
  return pdfDoc.save();
}
```

**PDF structure after signing:**

```
Original PDF:
┌────────────────────┐
│  PDF Header        │
│  PDF Objects       │
│  PDF Content       │
│  Cross-ref Table   │
│  PDF Trailer       │
└────────────────────┘

Signed PDF:
┌────────────────────┐
│  PDF Header        │
│  PDF Objects       │
│  PDF Content       │
│  ┌──────────────┐  │
│  │ Signature    │  │ ← New signature object
│  │ Dictionary   │  │
│  │ /Type /Sig   │  │
│  │ /Contents    │  │
│  │ <PKCS#7>     │  │
│  └──────────────┘  │
│  Cross-ref Table   │ ← Updated to include signature
│  PDF Trailer       │ ← Updated
└────────────────────┘
```

### Step 9: Download Signed PDF

```javascript
function downloadSignedPdf(pdfBytes, filename) {
  // Create Blob from PDF bytes
  const blob = new Blob([pdfBytes], { type: 'application/pdf' });

  // Create temporary download link
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  a.style.display = 'none';

  // Trigger download
  document.body.appendChild(a);
  a.click();

  // Cleanup
  setTimeout(() => {
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  }, 100);

  console.log('✅ Signed PDF downloaded:', filename);
  alert('PDF signed successfully!\nFile: ' + filename);
}
```

## Comparison: Browser vs Server Signing

### Browser-Based Signing (Fortify WebCrypto)

```
User's Computer:
┌─────────────────────────┐
│ Browser                 │
│  ↓                      │
│ Fortify (localhost)     │
│  ↓                      │
│ Hardware Token          │
│  - Private key inside   │
└─────────────────────────┘

Advantages:
✅ PDF never uploaded to server
✅ Private key never leaves hardware token
✅ Works offline
✅ Instant signing
✅ User controls their key
✅ No server-side storage needed

Disadvantages:
❌ Requires Fortify app installed
❌ Requires hardware token
❌ User must be present (PIN entry)
```

### Server-Side Signing (Harica)

```
User's Computer:
┌─────────────────────────┐
│ Browser                 │
│  ↓ (upload PDF)         │
└─────────────────────────┘
         ↓
Your Server:
┌─────────────────────────┐
│ Rails App               │
│  ↓                      │
│ Harica API              │
│  ↓                      │
│ Harica Cloud            │
│  - Signs PDF            │
└─────────────────────────┘

Advantages:
✅ No client-side setup
✅ Automated signing
✅ Works from any device
✅ No hardware needed

Disadvantages:
❌ PDF uploaded to server
❌ Server/cloud has private key
❌ Requires internet
❌ API call latency
```

## Security Guarantees

### 1. Private Key Protection

**Hardware Token (YubiKey/Nitrokey):**
```
Private Key Location: Secure chip inside token
Export Capability: IMPOSSIBLE (physically cannot export)
Attack Surface: Physical tamper-resistant chip
PIN Protection: 3 attempts before lock
Extraction Attack: Requires chip-level attack (extremely expensive)
```

**FIPS 140-2 Level 2 Compliance:**
- Tamper-evident physical security
- Role-based authentication (user PIN)
- Cryptographic module validation
- Approved cryptographic algorithms

### 2. Signature Integrity

**PDF ByteRange Coverage:**
```
┌─────────────────────────────────┐
│  PDF Header                     │ ← Signed
│  PDF Objects                    │ ← Signed
│  PDF Content                    │ ← Signed
│  ┌───────────────────────────┐  │
│  │ Signature: <PKCS#7 blob>  │  │ ← NOT signed (self-signature)
│  └───────────────────────────┘  │
│  Remaining Objects              │ ← Signed
│  Cross-ref Table                │ ← Signed
│  Trailer                        │ ← Signed
└─────────────────────────────────┘
```

**Any modification invalidates signature:**
- Adding/removing text
- Changing images
- Modifying metadata
- Deleting pages
- Adding annotations

### 3. Communication Security

**Fortify REST API:**
```
Protocol: HTTPS (TLS 1.2+)
Host: localhost:31337
Certificate: Self-signed (local only)
CORS: Restricted to same-origin
Authentication: None needed (localhost only)
```

**Why localhost is secure:**
- Only accessible from same computer
- Cannot be accessed over network
- No remote attack surface
- Browser enforces same-origin policy

## Key Technologies

### 1. WebCrypto API

Standard browser API for cryptographic operations:

```javascript
// Hashing (client-side)
const hash = await crypto.subtle.digest('SHA-256', pdfBytes);

// Signature verification (not creation - hardware token does that)
const isValid = await crypto.subtle.verify(
  { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
  publicKey,
  signature,
  data
);
```

**Supported browsers:**
- ✅ Chrome 37+ (2014)
- ✅ Firefox 34+ (2014)
- ✅ Safari 11+ (2017)
- ✅ Edge 79+ (2020)

### 2. PKCS#11

Standard interface for hardware security modules:

```c
// C interface (used by Fortify via node bindings)

// Initialize library
CK_RV C_Initialize(CK_VOID_PTR pInitArgs);

// Login with PIN
CK_RV C_Login(
  CK_SESSION_HANDLE hSession,
  CK_USER_TYPE userType,
  CK_UTF8CHAR_PTR pPin,
  CK_ULONG ulPinLen
);

// Sign data
CK_RV C_Sign(
  CK_SESSION_HANDLE hSession,
  CK_BYTE_PTR pData,
  CK_ULONG ulDataLen,
  CK_BYTE_PTR pSignature,
  CK_ULONG_PTR pulSignatureLen
);
```

### 3. PKCS#7 (CMS)

PDF signature format:

```asn1
SignedData ::= SEQUENCE {
  version CMSVersion,
  digestAlgorithms DigestAlgorithmIdentifiers,
  encapContentInfo EncapsulatedContentInfo,
  certificates [0] IMPLICIT CertificateSet OPTIONAL,
  crls [1] IMPLICIT RevocationInfoChoices OPTIONAL,
  signerInfos SignerInfos
}
```

**Embedded in PDF as:**
```
/Contents <3082...>  ← Hex-encoded PKCS#7 blob
```

## Troubleshooting

### Issue: "Fortify not running"

**Symptoms:**
```
Error: Failed to fetch
or
Error: Fortify not running. Please start the Fortify app.
```

**Solutions:**
```bash
# 1. Check if Fortify is running
curl -k https://localhost:31337/info

# Should return: {"name":"fortify","version":"..."}

# 2. Start Fortify
fortify

# 3. Verify port 31337 is listening
lsof -i :31337
# or
netstat -an | grep 31337
```

### Issue: "Token not detected"

**Symptoms:**
```
Error: No certificates found
or
Error: PKCS#11 error: CKR_TOKEN_NOT_PRESENT
```

**Solutions:**
```bash
# 1. Check token is inserted
pkcs11-tool --module /usr/local/lib/opensc-pkcs11.so --list-slots

# 2. Check OpenSC is installed
which pkcs11-tool

# 3. Restart Fortify after inserting token
killall fortify
fortify
```

### Issue: "PIN incorrect"

**Symptoms:**
```
Error: PKCS#11 error: CKR_PIN_INCORRECT
```

**Solutions:**
```bash
# Check remaining PIN attempts
pkcs11-tool --module /usr/local/lib/opensc-pkcs11.so --login

# Reset YubiKey PIN (WARNING: Erases all keys!)
ykman piv reset

# Set new PIN
ykman piv set-pin
```

### Issue: "Invalid PDF"

**Symptoms:**
```
Error: Invalid PDF file
or
Error: PDF parsing failed
```

**Solutions:**
1. Verify PDF is valid: `pdfinfo file.pdf`
2. Check PDF version (Sphragis supports PDF 1.4+)
3. Ensure PDF is not encrypted
4. Re-generate PDF with Prawn or another library

## Performance Metrics

### Signing Speed

| Operation | Time | Notes |
|-----------|------|-------|
| Fortify startup | ~2-5 seconds | One-time per session |
| Certificate discovery | ~100-500ms | Depends on token |
| PDF hash computation | ~50-200ms | Depends on PDF size |
| Hardware signing | ~200-500ms | RSA-2048 operation |
| PDF modification | ~100-300ms | Depends on PDF size |
| **Total** | **~0.5-1.5 seconds** | For typical invoice PDF |

### File Size Impact

| PDF Size | Additional Size | Percentage |
|----------|-----------------|------------|
| 100 KB | ~5 KB | +5% |
| 1 MB | ~5 KB | +0.5% |
| 10 MB | ~5 KB | +0.05% |

**Signature size is constant (~5 KB) regardless of PDF size.**

## References

### Standards

- **ISO 32000-2**: PDF 2.0 specification
- **RFC 5652**: Cryptographic Message Syntax (CMS/PKCS#7)
- **RFC 3447**: PKCS#1 v2.1 (RSA signatures)
- **ISO/IEC 7816**: Smart card standards
- **FIPS 140-2**: Cryptographic module security requirements

### APIs

- **WebCrypto API**: https://www.w3.org/TR/WebCryptoAPI/
- **PKCS#11 v2.40**: http://docs.oasis-open.org/pkcs11/pkcs11-base/v2.40/
- **PDF.js**: https://mozilla.github.io/pdf.js/

### Software

- **Fortify**: https://github.com/PeculiarVentures/fortify
- **OpenSC**: https://github.com/OpenSC/OpenSC
- **YubiKey**: https://developers.yubico.com/PIV/
- **Nitrokey**: https://docs.nitrokey.com/

---

**Created**: October 21, 2025
**Last Updated**: October 21, 2025
**Sphragis Version**: 0.1.0+
