# Multi-Provider Architecture

> **⚠️ EARLY DEVELOPMENT VERSION**
>
> This gem is in early development and has not been thoroughly tested in production environments.
> Use at your own risk and test extensively before deploying to production.

## Overview

Sphragis supports multiple signature providers, giving you flexibility to choose between:

1. **Hardware Tokens** (Fortify WebCrypto) - Highest security, FREE software + €50 hardware
2. **Cloud E-Signatures** (Harica) - eIDAS qualified, FREE for academic/paid for commercial
3. **Free Services** (Itsme template) - For development and internal use

## Quick Start

### 1. Configure Multiple Providers

```ruby
# config/initializers/sphragis.rb
Sphragis.configure do |config|
  # Set default provider
  config.default_provider = :harica

  # Configure Fortify WebCrypto (FREE software)
  config.fortify_url = "https://localhost:31337"
  config.fortify_certificate_id = "cert_id"

  # Configure Harica (FREE for academic)
  config.harica_api_key = Rails.application.credentials.dig(:harica, :api_key)
  config.harica_certificate_id = "cert_12345"
  config.harica_username = "your.email@university.gr"
  config.harica_password = Rails.application.credentials.dig(:harica, :password)
  config.harica_environment = "production"

  # Configure Itsme (or other free service)
  config.itsme_client_id = ENV["ITSME_CLIENT_ID"]
  config.itsme_client_secret = Rails.application.credentials.dig(:itsme, :secret)
  config.itsme_user_email = "user@example.com"
  config.itsme_environment = "production"
end
```

### 2. Use in Your Application

```ruby
# Let user choose provider
class DocumentsController < ApplicationController
  def sign
    @document = Document.find(params[:id])

    # Option 1: Use interactive UI (user selects provider)
    redirect_to sphragis.preview_path(path: @document.pdf.path)
  end

  def sign_with_provider
    @document = Document.find(params[:id])
    provider = params[:provider]&.to_sym || :harica

    # Option 2: Programmatic signing with specific provider
    signer = Sphragis::PdfSigner.new(@document.pdf.path, {
      provider: provider,
      reason: "Document approved",
      location: "University of Aegean"
    })

    signed_path = signer.sign
    redirect_to signed_document_path(@document), notice: "Document signed with #{provider}"
  end
end
```

## Provider Selection Strategies

### Strategy 1: User Choice (Recommended)

Let users select their preferred provider:

```ruby
# app/views/documents/sign_options.html.erb
<%= form_with url: sign_document_path(@document) do |f| %>
  <h3>Select Signature Provider:</h3>

  <% Sphragis::ProviderFactory.available_providers.each do |provider| %>
    <div class="provider-option">
      <%= f.radio_button :provider, provider, id: "provider_#{provider}" %>
      <%= f.label "provider_#{provider}", provider.to_s.titleize %>
      <p class="provider-description">
        <%= provider_description(provider) %>
      </p>
    </div>
  <% end %>

  <%= f.submit "Continue to Signature Placement" %>
<% end %>
```

Helper:
```ruby
# app/helpers/documents_helper.rb
def provider_description(provider)
  case provider
  when :harica
    "🏛️ Greek Academic CA - FREE for universities, eIDAS qualified"
  when :fortify_webcrypto
    "🔐 Hardware Token - Maximum security with YubiKey/Nitrokey"
  when :itsme
    "📝 Free Service - Simple electronic signature"
  else
    provider.to_s.titleize
  end
end
```

### Strategy 2: Role-Based Selection

Different providers for different user roles:

```ruby
class DocumentsController < ApplicationController
  def sign
    provider = select_provider_for_user(current_user)

    signer = Sphragis::PdfSigner.new(@document.pdf.path, {
      provider: provider,
      reason: "Signed by #{current_user.role}"
    })

    signer.sign
  end

  private

  def select_provider_for_user(user)
    case user.role
    when 'admin', 'dean'
      # Use hardware token for highest authority
      :fortify_webcrypto
    when 'professor', 'researcher'
      # Use Harica for academic staff
      :harica
    when 'student'
      # Use simple signature for students
      :itsme
    else
      Sphragis.configuration.default_provider
    end
  end
end
```

### Strategy 3: Document Type Selection

Different providers based on document importance:

```ruby
class Document < ApplicationRecord
  enum sensitivity: {
    public: 0,
    internal: 1,
    confidential: 2,
    restricted: 3
  }

  def recommended_provider
    case sensitivity
    when 'restricted', 'confidential'
      # Use hardware token for sensitive documents
      :fortify_webcrypto
    when 'internal'
      # Use Harica for official academic documents
      :harica
    else
      # Use simple provider for public documents
      :itsme
    end
  end
end

# Usage
signer = Sphragis::PdfSigner.new(document.pdf.path, {
  provider: document.recommended_provider
})
```

### Strategy 4: Cost-Based Selection

Balance between cost and security:

```ruby
class SignatureService
  def self.sign_with_optimal_provider(document, user)
    provider = if user.department.budget_remaining > 100
      # Use paid provider if budget available
      :fortify_webcrypto
    elsif user.email.ends_with?('.gr.ac')
      # Use free academic provider
      :harica
    else
      # Use free general provider
      :itsme
    end

    Sphragis::PdfSigner.new(document.path, { provider: provider }).sign
  end
end
```

## Checking Available Providers

### List All Configured Providers

```ruby
# In controller or view
available = Sphragis::ProviderFactory.available_providers
# => [:harica, :fortify_webcrypto]

# Show to user
<% available.each do |provider| %>
  <option value="<%= provider %>"><%= provider.to_s.titleize %></option>
<% end %>
```

### Check Specific Provider

```ruby
# Check if Harica is configured
if Sphragis.configuration.harica_configured?
  # Use Harica
  provider = :harica
else
  # Fall back to default
  provider = Sphragis.configuration.default_provider
end
```

### Get Provider Details

```ruby
provider = Sphragis::ProviderFactory.create(:harica)
details = {
  name: provider.provider_name,
  type: provider.provider_type,
  available: provider.configured?
}
```

## Provider Comparison for Users

Display provider comparison to help users choose:

```erb
<table class="provider-comparison">
  <thead>
    <tr>
      <th>Provider</th>
      <th>Security Level</th>
      <th>Cost</th>
      <th>Speed</th>
      <th>Legal Validity</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>🏛️ Harica</td>
      <td>⭐⭐⭐⭐⭐ Qualified</td>
      <td>FREE (Academic)</td>
      <td>Fast (Cloud)</td>
      <td>eIDAS Qualified</td>
    </tr>
    <tr>
      <td>🔐 Fortify WebCrypto</td>
      <td>⭐⭐⭐⭐⭐ Qualified*</td>
      <td>€50 (One-time)</td>
      <td>Very Fast (Local)</td>
      <td>High (with CA cert)</td>
    </tr>
    <tr>
      <td>📝 Itsme</td>
      <td>⭐⭐⭐ Simple</td>
      <td>FREE</td>
      <td>Fast</td>
      <td>Internal Use</td>
    </tr>
  </tbody>
</table>
<p class="footnote">*Requires certificate from trusted CA like Harica</p>
```

## Fallback Strategy

Handle provider failures gracefully:

```ruby
class SignatureService
  PROVIDER_PRIORITY = [:fortify_webcrypto, :harica, :itsme]

  def self.sign_with_fallback(pdf_path, options = {})
    last_error = nil

    PROVIDER_PRIORITY.each do |provider|
      next unless Sphragis::ProviderFactory.available?(provider)

      begin
        signer = Sphragis::PdfSigner.new(pdf_path, options.merge(provider: provider))
        return signer.sign
      rescue => e
        last_error = e
        Rails.logger.warn "Provider #{provider} failed: #{e.message}"
        next
      end
    end

    raise "All providers failed. Last error: #{last_error&.message}"
  end
end
```

## Environment-Based Configuration

Different providers for different environments:

```ruby
# config/initializers/sphragis.rb
Sphragis.configure do |config|
  case Rails.env
  when 'production'
    # Use Harica in production
    config.default_provider = :harica
    config.harica_environment = "production"

  when 'staging'
    # Use Harica sandbox in staging
    config.default_provider = :harica
    config.harica_environment = "sandbox"

  when 'development', 'test'
    # Use simulated provider in development
    config.default_provider = :itsme
    config.itsme_environment = "sandbox"
  end
end
```

## Multi-Signature Documents

Sign with multiple providers for extra verification:

```ruby
class Document < ApplicationRecord
  def sign_with_multiple_providers!(providers = [:harica, :fortify_webcrypto])
    current_path = pdf.path

    providers.each_with_index do |provider, index|
      signer = Sphragis::PdfSigner.new(current_path, {
        provider: provider,
        reason: "Signature #{index + 1}/#{providers.count}",
        y: 100 + (index * 100)  # Stack signatures vertically
      })

      current_path = signer.sign
    end

    # Update document with multi-signed version
    self.pdf.attach(io: File.open(current_path), filename: "signed_#{id}.pdf")
  end
end
```

## Provider Statistics

Track provider usage for analytics:

```ruby
class SignatureAudit < ApplicationRecord
  belongs_to :document
  belongs_to :user

  after_create :update_provider_stats

  def update_provider_stats
    ProviderStat.increment_counter(:signatures_count, provider)
  end
end

# Usage
def sign_and_audit
  provider = params[:provider]&.to_sym

  signer = Sphragis::PdfSigner.new(@document.pdf.path, { provider: provider })
  signed_path = signer.sign

  SignatureAudit.create!(
    document: @document,
    user: current_user,
    provider: provider,
    certificate_info: signer.certificate
  )
end
```

## Provider Health Checks

Monitor provider availability:

```ruby
class ProviderHealthCheck
  def self.check_all
    Sphragis::ProviderFactory.available_providers.map do |provider_name|
      {
        name: provider_name,
        status: check_provider(provider_name),
        last_checked: Time.current
      }
    end
  end

  def self.check_provider(provider_name)
    provider = Sphragis::ProviderFactory.create(provider_name)
    provider.connect
    provider.connected? ? 'healthy' : 'unavailable'
  rescue => e
    'error'
  ensure
    provider&.disconnect
  end
end

# Dashboard
<% ProviderHealthCheck.check_all.each do |health| %>
  <div class="provider-status <%= health[:status] %>">
    <%= health[:name] %>: <%= health[:status] %>
  </div>
<% end %>
```

## Credits & Acknowledgments

This multi-provider architecture integrates with:

- **[Fortify by Peculiar Ventures](https://github.com/PeculiarVentures/fortify)** - FREE WebCrypto bridge (MIT License)
- **[HARICA](https://www.harica.gr)** - Greek Academic CA (FREE for academic institutions)
- **[Prawn PDF](https://github.com/prawnpdf/prawn)** - Ruby PDF generation (GPL/Commercial)
- **[PDF.js](https://mozilla.github.io/pdf.js/)** - JavaScript PDF rendering (Apache 2.0)

## See Also

- [PROVIDERS.md](PROVIDERS.md) - Detailed provider comparison
- [FORTIFY_WEBCRYPTO.md](FORTIFY_WEBCRYPTO.md) - Fortify setup guide
- [LICENSING_SUMMARY.md](LICENSING_SUMMARY.md) - Cost breakdown
