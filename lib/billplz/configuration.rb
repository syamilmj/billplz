module Billplz
  class Configuration
    LIVE_HOST    = 'https://www.billplz.com/api'.freeze
    SANDBOX_HOST = 'https://www.billplz-sandbox.com/api'.freeze

    OPTIONS = %w[api_key x_signature_key http_timeout mode].freeze

    # x_signature_key is a separate credential from api_key. It signs callbacks
    # and redirects (HMAC-SHA256) and V5 checksums (HMAC-SHA512).
    attr_accessor :api_key, :x_signature_key, :http_timeout, :mode

    def initialize(options = {})
      @http_timeout = 30
      @mode         = 'live'

      options.each { |key, value| send("#{key}=", value) }
    end

    def sandbox?
      mode.to_s == 'sandbox'
    end

    def host
      sandbox? ? SANDBOX_HOST : LIVE_HOST
    end

    def options
      OPTIONS.each_with_object({}) { |key, hash| hash[key.to_sym] = send(key) }
    end
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configuration=(args)
    @configuration ||= Configuration.new
    args.each do |arg|
      @configuration.send("#{arg.first}=", arg.last)
    end
  end

  def self.options
    configuration.options
  end

  def self.configure
    yield configuration
  end

  def self.reset
    @configuration = nil
  end
end
