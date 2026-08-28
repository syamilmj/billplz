# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'billplz/version'

Gem::Specification.new do |spec|
  spec.name          = "billplz"
  spec.version       = Billplz::VERSION

  spec.summary       = 'Abstraction library to interface with the Billplz API'
  spec.description   = 'A dependency-free Ruby client for the Billplz payment API, covering collections, ' \
                       'bills, payment gateways and V5 payment orders, with X Signature webhook verification ' \
                       'and sandbox support.'
  spec.license       = 'MIT'
  spec.author        = 'Syamil MJ'
  spec.homepage      = 'https://github.com/syamilmj/billplz'

  spec.required_ruby_version = '>= 3.1'

  spec.metadata = {
    'homepage_uri'    => spec.homepage,
    'source_code_uri' => spec.homepage,
    'bug_tracker_uri' => "#{spec.homepage}/issues"
  }

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "webmock", "~> 3.0"
end
