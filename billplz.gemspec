# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'billplz/version'

Gem::Specification.new do |spec|
  spec.name          = "billplz"
  spec.version       = Billplz::VERSION

  spec.summary       = 'Abstraction library to interface with the Billplz API'
  spec.license       = 'MIT'
  spec.author        = 'Syamil MJ'
  spec.email         = 'syamilmj@tideee.com'
  spec.homepage      = 'https://github.com/tideee/billplz'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake"
  spec.add_development_dependency "test-unit"
  spec.add_development_dependency "mocha"
end
