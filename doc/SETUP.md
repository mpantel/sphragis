# Sphragis Setup Guide

## Quick Start

### 1. Installation

Add to your Rails application's Gemfile:

```ruby
gem 'sphragis', path: '../sphragis'  # for local development
# or
gem 'sphragis'  # once published
```

Then run:

```bash
bundle install
```

### 2. Mount the Engine

In `config/routes.rb`:

```ruby
Rails.application.routes.draw do
  mount Sphragis::Engine => "/sphragis"
  # Your other routes...
end
```

### 3. Configure

Create `config/initializers/sphragis.rb`:

```ruby
Sphragis.configure do |config|
  config.fortify_library_path = ENV.fetch('FORTIFY_LIBRARY_PATH', '/usr/lib/fortify/libfortify.so')
  config.token_pin = Rails.application.credentials.dig(:fortify, :token_pin)
  config.token_slot = ENV.fetch('FORTIFY_TOKEN_SLOT', '0').to_i
  config.certificate_label = ENV.fetch('FORTIFY_CERTIFICATE_LABEL', 'Signing Certificate')
end
```

### 4. Set up Rails Credentials

```bash
EDITOR=vim rails credentials:edit
```

Add:

```yaml
fortify:
  token_pin: your_secret_pin_here
```

## Usage Examples

### In a Controller

```ruby
class DocumentsController < ApplicationController
  def sign
    @document = Document.find(params[:id])

    # Option 1: Redirect to interactive preview
    redirect_to sphragis.preview_path(path: @document.pdf.path)
  end

  def sign_programmatically
    @document = Document.find(params[:id])

    signer = Sphragis::PdfSigner.new(@document.pdf.path, {
      x: 400,
      y: 50,
      width: 150,
      height: 50,
      page: 1,
      reason: "Approved by #{current_user.name}",
      location: "Athens, Greece"
    })

    signed_path = signer.sign

    # Save the signed PDF
    @document.update(signed_pdf: signed_path)

    redirect_to @document, notice: 'Document signed successfully'
  rescue Sphragis::PdfSigner::SigningError => e
    redirect_to @document, alert: "Signing failed: #{e.message}"
  end
end
```

### Generating and Signing PDFs with Prawn

```ruby
class Invoice < ApplicationRecord
  def generate_and_sign_pdf
    # Generate PDF
    pdf_path = Rails.root.join('tmp', "invoice_#{id}.pdf")

    Prawn::Document.generate(pdf_path) do |pdf|
      pdf.text "Invoice ##{id}"
      pdf.text "Date: #{created_at.strftime('%Y-%m-%d')}"
      pdf.move_down 20
      pdf.text "Total: $#{total}"
    end

    # Sign the PDF
    signer = Sphragis::PdfSigner.new(pdf_path, {
      reason: "Invoice approval",
      location: "Company HQ"
    })

    signed_path = signer.sign

    # Attach to record
    self.signed_invoice.attach(
      io: File.open(signed_path),
      filename: "invoice_#{id}_signed.pdf",
      content_type: 'application/pdf'
    )

    # Clean up temp files
    File.delete(pdf_path) if File.exist?(pdf_path)

    signed_path
  end
end
```

## Testing

Run the test suite:

```bash
cd sphragis
bundle install
bundle exec rake test
```

All tests should pass:

```
38 runs, 109 assertions, 0 failures, 0 errors, 0 skips
```

## Development

### Running Console

```bash
cd sphragis
bin/console
```

Try it out:

```ruby
# Configure
Sphragis.configure do |config|
  config.token_pin = "123456"
end

# Test token connection
token = Sphragis::HardwareToken.new
token.connect
token.certificate
token.disconnect

# Create a test PDF
require 'prawn'
Prawn::Document.generate("test.pdf") { |pdf| pdf.text "Test" }

# Sign it
signer = Sphragis::PdfSigner.new("test.pdf")
signer.sign
```

## Architecture

### Components

1. **Engine** (`lib/sphragis/engine.rb`)
   - Rails Engine configuration
   - Asset pipeline setup

2. **Configuration** (`lib/sphragis/configuration.rb`)
   - Token settings
   - Library paths
   - Certificate labels

3. **HardwareToken** (`lib/sphragis/hardware_token.rb`)
   - Fortify integration
   - PKCS#11 operations (simulated)
   - Digital signature generation

4. **PdfSigner** (`lib/sphragis/pdf_signer.rb`)
   - PDF signing logic
   - Signature placement
   - Integration with HardwareToken

5. **DocumentsController** (`app/controllers/sphragis/documents_controller.rb`)
   - Preview endpoint
   - Signing endpoint
   - Validation endpoint

6. **Interactive UI** (`app/views/sphragis/documents/preview.html.erb`)
   - PDF.js viewer
   - Drag-and-drop signature placement
   - Real-time preview

### Routes

- `GET /sphragis/preview` - Interactive PDF preview and signing
- `GET /sphragis/view` - View PDF file
- `POST /sphragis/sign` - Sign PDF (API)
- `GET /sphragis/validate_placement` - Validate signature position

## Security Checklist

- [ ] Never commit token PIN to version control
- [ ] Use Rails credentials or environment variables for sensitive data
- [ ] Implement authorization checks before allowing signing
- [ ] Use HTTPS in production
- [ ] Audit all signing operations
- [ ] Secure Fortify library access at OS level
- [ ] Regularly rotate token PINs
- [ ] Monitor failed signing attempts

## Troubleshooting

### Token Not Found

```ruby
# Check library path
File.exist?(Sphragis.configuration.fortify_library_path)
```

### Connection Failed

```ruby
# Test connection
token = Sphragis::HardwareToken.new
begin
  token.connect
  puts "Success!"
rescue => e
  puts "Error: #{e.message}"
end
```

### Invalid PDF

```ruby
# Validate PDF
require 'pdf-reader'
PDF::Reader.new(pdf_path).page_count
```

## Next Steps

1. Install Fortify library on your system
2. Configure hardware token
3. Set up Rails credentials
4. Test in development
5. Deploy to production
6. Set up monitoring and logging

## Support

- GitHub: https://github.com/yourusername/sphragis
- Email: mpantel@aegean.gr
