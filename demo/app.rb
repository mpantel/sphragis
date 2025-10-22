require 'sinatra'
require 'sinatra/reloader' if development?
require 'fileutils'
require 'json'
require 'sphragis'

# Configure Sphragis with multiple providers for demo purposes
Sphragis.configure do |config|
  # Configure all providers with demo values so they're available
  config.default_provider = :itsme

  # Fortify WebCrypto (demo config)
  config.fortify_library_path = "/usr/lib/fortify/libfortify.so"
  config.token_pin = "demo-pin"
  config.token_slot = 0
  config.certificate_label = "Demo Certificate"

  # Harica (demo config)
  config.harica_api_key = "demo-api-key"
  config.harica_certificate_id = "demo-cert-id"
  config.harica_username = "demo@example.com"
  config.harica_password = "demo-password"
  config.harica_environment = "sandbox"

  # Itsme (demo config)
  config.itsme_client_id = "demo-client-id"
  config.itsme_client_secret = "demo-secret"
  config.itsme_user_email = "demo@example.com"
  config.itsme_environment = "sandbox"
end

class DemoApp < Sinatra::Base
  enable :sessions
  set :public_folder, 'public'
  set :views, 'views'

  # Ensure upload directory exists
  FileUtils.mkdir_p('uploads')

  # Home page with upload form
  get '/' do
    erb :index
  end

  # Handle PDF upload
  post '/upload' do
    if params[:pdf] && params[:pdf][:tempfile]
      filename = params[:pdf][:filename]
      file_path = File.join('uploads', filename)

      # Save the uploaded file
      File.open(file_path, 'wb') do |f|
        f.write params[:pdf][:tempfile].read
      end

      session[:pdf_path] = file_path
      session[:pdf_filename] = filename

      redirect '/preview'
    else
      @error = "Please select a PDF file to upload"
      erb :index
    end
  end

  # Get available signature providers
  get '/providers' do
    content_type :json
    begin
      providers = Sphragis::ProviderFactory.available_providers
      default = Sphragis::ProviderFactory.default_provider

      provider_info = {
        fortify: {
          name: "Fortify WebCrypto",
          description: "Hardware token signing (YubiKey, etc.)"
        },
        harica: {
          name: "Harica",
          description: "Greek Academic qualified e-signatures"
        },
        itsme: {
          name: "Itsme (Simulated)",
          description: "Template/simulated provider for testing"
        }
      }

      {
        providers: providers,
        default: default,
        info: provider_info.select { |k, _| providers.include?(k) }
      }.to_json
    rescue => e
      { error: e.message }.to_json
    end
  end

  # Preview page for signature placement
  get '/preview' do
    pdf_path = session[:pdf_path]

    unless pdf_path && File.exist?(pdf_path)
      redirect '/'
      return
    end

    @pdf_filename = session[:pdf_filename]
    @pdf_url = "/uploads/#{File.basename(pdf_path)}"

    erb :preview
  end

  # Handle signature placement and signing
  post '/sign' do
    pdf_path = session[:pdf_path]

    unless pdf_path && File.exist?(pdf_path)
      return { error: "PDF file not found" }.to_json
    end

    begin
      # Get signature placement from request
      x = params[:x].to_f
      y = params[:y].to_f
      width = params[:width].to_f
      height = params[:height].to_f
      page = params[:page].to_i

      # Get provider from request (default to itsme)
      provider = params[:provider]&.to_sym || :itsme

      # Validate provider is available
      unless Sphragis::ProviderFactory.available_providers.include?(provider)
        return { success: false, error: "Provider #{provider} is not available" }.to_json
      end

      # Sign the PDF
      signer = Sphragis::PdfSigner.new(pdf_path, {
        provider: provider,
        reason: params[:reason] || "Demo signature",
        location: params[:location] || "Demo App",
        contact: params[:contact] || "demo@sphragis.dev",
        x: x,
        y: y,
        width: width,
        height: height,
        page: page
      })

      signed_path = signer.sign
      signed_filename = "signed_#{session[:pdf_filename]}"
      final_path = File.join('uploads', signed_filename)

      FileUtils.mv(signed_path, final_path)

      content_type :json
      { success: true, download_url: "/download/#{signed_filename}", provider: provider }.to_json
    rescue => e
      content_type :json
      { success: false, error: e.message }.to_json
    end
  end

  # Download signed PDF
  get '/download/:filename' do
    file_path = File.join('uploads', params[:filename])

    if File.exist?(file_path)
      send_file file_path, filename: params[:filename], type: 'application/pdf'
    else
      404
    end
  end

  # Serve uploaded files
  get '/uploads/:filename' do
    file_path = File.join('uploads', params[:filename])

    if File.exist?(file_path)
      send_file file_path, type: 'application/pdf'
    else
      404
    end
  end
end
