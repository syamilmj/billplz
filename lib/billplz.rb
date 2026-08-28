require 'net/http'
require 'uri'
require 'json'
require 'cgi'
require 'openssl'

require "billplz/version"
require "billplz/configuration"
require "billplz/signature"
require "billplz/model"
require "billplz/bill"
require "billplz/collection"
require "billplz/open_collection"
require "billplz/fpx_bank"
require "billplz/payment_gateway"
require "billplz/webhook_rank"
require "billplz/payment_order_collection"
require "billplz/payment_order"
require "billplz/payment_order_limit"

module Billplz
  # The API accepts both form-encoded and JSON bodies, but only form encoding
  # is exercised by the documentation — and nested arguments such as
  # split_payments[][email] are only specified in that form.
  #
  # nil values are dropped rather than sent empty, which matters for V5:
  # an omitted optional argument must also drop out of the checksum.
  def self.encode_form(params, prefix = nil)
    case params
    when Hash
      params.map { |key, value|
        encode_form(value, prefix ? "#{prefix}[#{key}]" : key.to_s)
      }.reject(&:empty?).join('&')
    when Array
      params.map { |value| encode_form(value, "#{prefix}[]") }.reject(&:empty?).join('&')
    when nil
      ''
    else
      "#{CGI.escape(prefix.to_s)}=#{CGI.escape(params.to_s)}"
    end
  end
end
