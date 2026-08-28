module Billplz
  # Verifies that a bill callback or redirect actually came from Billplz.
  #
  # X Signature is enabled by default on every account registered from
  # September 2018. Without this check a callback handler cannot tell a real
  # webhook from anyone POSTing to the same URL.
  #
  #   Billplz::Signature.verify(params) # => true / false
  #
  # Handles both shapes: the callback POSTs flat params, while the redirect
  # arrives nested under billplz[...] — whether your framework hands that over
  # already parsed into a hash or still as literal "billplz[id]" keys.
  module Signature
    module_function

    # Elements are key and value concatenated, sorted case-insensitively, and
    # joined with a pipe. Nested keys have their parent prepended and their
    # brackets stripped: billplz[id] signs as "billplzid".
    def source_string(params)
      flatten(params).
        reject { |key, _| key.end_with?('x_signature') }.
        map { |key, value| "#{key}#{value}" }.
        sort_by(&:downcase).
        join('|')
    end

    def sign(params, key = nil)
      OpenSSL::HMAC.hexdigest('SHA256', signing_key(key), source_string(params))
    end

    def verify(params, key = nil)
      received = signature_in(params)
      return false if received.nil? || received.empty?

      secure_compare(sign(params, key), received)
    end

    # V5 signs differently: the values of that endpoint's documented checksum
    # arguments, in order, concatenated with no separator and no key names,
    # digested with SHA512. Arguments that were not supplied are omitted.
    def checksum(values, key = nil)
      OpenSSL::HMAC.hexdigest('SHA512', signing_key(key), Array(values).compact.join)
    end

    def flatten(params, prefix = nil, pairs = [])
      params.each do |key, value|
        name = "#{prefix}#{key}".delete('[]')

        case value
        when Hash
          flatten(value, name, pairs)
        when Array
          value.each { |item| item.is_a?(Hash) ? flatten(item, name, pairs) : pairs << [name, item] }
        else
          pairs << [name, value]
        end
      end

      pairs
    end

    def signature_in(params)
      pair = flatten(params).find { |key, _| key.end_with?('x_signature') }
      pair && pair.last.to_s
    end

    def signing_key(key)
      key ||= Billplz.configuration.x_signature_key
      raise ArgumentError, "Missing X Signature key. Set Billplz.configuration.x_signature_key or pass one." if key.nil? || key.to_s.empty?
      key.to_s
    end

    def secure_compare(a, b)
      a.bytesize == b.bytesize && OpenSSL.fixed_length_secure_compare(a, b)
    end
  end
end
