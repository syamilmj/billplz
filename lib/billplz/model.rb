module Billplz
  class Model
    attr_accessor :payload
    attr_accessor :response

    # options[:version] overrides the class-level API version for this
    # instance: Billplz::Collection.new({ title: 'x' }, version: 'v4')
    #
    # It is a positional hash rather than a keyword on purpose — declaring a
    # keyword would make Ruby 3 read a brace-less Bill.new(name: 'x') as
    # keywords rather than as the payload.
    def initialize(payload = {}, options = {})
      @payload = payload
      @version = options[:version]
    end

    class << self
      attr_writer :api_url
      attr_accessor :api_version, :resource

      # Set only when a subclass hardcodes a full URL. Left nil, the URL is
      # built from the configured host, the API version and the resource.
      def api_url
        @api_url
      end
    end

    def version
      @version || self.class.api_version
    end

    def api_url(for_version = version)
      self.class.api_url || "#{Billplz.configuration.host}/#{for_version}/#{self.class.resource}"
    end

    def endpoint(path = nil, query = nil, for_version = version)
      url = path ? "#{api_url(for_version)}/#{path}" : api_url(for_version)
      url = "#{url}?#{Billplz.encode_form(query)}" if query && !query.empty?
      URI.parse(url)
    end

    # +version+ pins a single call to an API version other than the instance's,
    # for endpoints that only exist under one (e.g. customer receipt delivery).
    def request(method, body = nil, path: nil, query: nil, version: nil)
      uri = endpoint(path, query, version || self.version).request_uri

      @response = case method
      when :get
        raise ArgumentError, "GET requests do not support a request body" if body
        http.get(uri, headers)
      when :post
        http.post(uri, Billplz.encode_form(body), headers)
      when :put
        http.put(uri, Billplz.encode_form(body), headers)
      when :patch
        http.patch(uri, Billplz.encode_form(body), headers)
      when :delete
        raise ArgumentError, "DELETE requests do not support a request body" if body
        http.delete(uri, headers)
      else
        raise ArgumentError, "Unsupported request method #{method.to_s.upcase}"
      end

      @response
    end

    def success?
      @response.is_a?(Net::HTTPSuccess)
    end

    def rate_limited?
      @response.is_a?(Net::HTTPTooManyRequests)
    end

    def parsed_json
      JSON.parse(@response.body)
    end

    # The API's error object, or nil on success. `message` is documented as an
    # array but is a string (and occasionally a hash) on some endpoints.
    def error
      return nil if success?
      parsed_json['error']
    rescue JSON::ParserError
      nil
    end

    # RateLimit-Reset is seconds remaining in the current window. All three
    # headers read "unlimited" when no limit is currently applied.
    def rate_limit
      return nil unless @response

      %w[limit remaining reset].each_with_object({}) do |name, hash|
        value = @response['RateLimit-' + name.capitalize]
        hash[name.to_sym] = value =~ /\A\d+\z/ ? value.to_i : value
      end
    end

    private

    def headers
      {
        # pack('m0') is strict base64 without the base64 gem, which stopped
        # being a default gem in Ruby 3.4. Keeps the gem dependency-free.
        "Authorization" => "Basic " + ["#{Billplz.configuration.api_key}:"].pack('m0'),
        "Content-Type"  => "application/x-www-form-urlencoded",
        "Accept"        => "application/json"
      }
    end

    def http
      uri = endpoint
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = Billplz.configuration.http_timeout
      http.read_timeout = Billplz.configuration.http_timeout
      http
    end

    # Signs a V5 payload. +fields+ are the endpoint's documented checksum
    # arguments, in order; +epoch+ is always appended last. Optional arguments
    # that were not supplied drop out of the digest entirely.
    def sign(payload, *fields)
      signed = payload.dup
      signed[:epoch] ||= Time.now.to_i
      signed[:checksum] = Signature.checksum((fields + [:epoch]).map { |field| signed[field] })
      signed
    end

    def requires!(hash, *params)
      params.each do |param|
        if param.is_a?(Array)
          raise ArgumentError.new("Missing required parameter: #{param.first}") unless hash.has_key?(param.first)

          valid_options = param[1..-1]
          raise ArgumentError.new("Parameter: #{param.first} must be one of #{valid_options.join(' or ')}") unless valid_options.include?(hash[param.first])
        else
          raise ArgumentError.new("Missing required parameter: #{param}") unless hash.has_key?(param)
        end
      end
    end

    # V5 GETs carry their epoch and checksum in the query string; the other
    # checksum arguments are already in the path.
    def signed_query(*fields)
      signed = sign(@payload, *fields)
      { epoch: signed[:epoch], checksum: signed[:checksum] }
    end

    def slice(*keys)
      @payload.select { |key, _| keys.include?(key) }
    end

    def requires_one_of!(hash, *params)
      return if params.any? { |param| hash.has_key?(param) }
      raise ArgumentError.new("Missing required parameter: one of #{params.join(' or ')}")
    end
  end
end
