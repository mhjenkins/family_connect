# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'family_connect/version'

Gem::Specification.new do |spec|
  spec.name          = "family_connect"
  spec.version       = FamilyConnect::VERSION
  spec.authors       = "Michael Jenkins"
  spec.email         = "michael.h.jenkins1@gmail.com"
  spec.description   = %q{This gem facilitates the discovery and connection to the family searc api}
  spec.summary       = %q{This gem facilitates the discovery and connection to the family searc api}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "typhoeus"
  spec.add_development_dependency "json"
end
