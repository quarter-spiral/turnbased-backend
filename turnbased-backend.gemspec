# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'turnbased/backend/version'

Gem::Specification.new do |spec|
  spec.name          = "turnbased-backend"
  spec.version       = Turnbased::Backend::VERSION
  spec.authors       = ["Thorben Schröder"]
  spec.email         = ["stillepost@gmail.com"]
  spec.description   = %q{A backend service to enable turn based multiplayer games on the Quarter Spiral platform.}
  spec.summary       = %q{A backend service to enable turn based multiplayer games on the Quarter Spiral platform.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"

  spec.add_dependency 'rack', '~> 1.4.5'
  spec.add_dependency 'grape', '~> 0.4.0'
  spec.add_dependency 'grape_newrelic', '~> 0.0.4'
  spec.add_dependency 'json', '~> 1.7.7'
  spec.add_dependency 'uuid'

  spec.add_dependency 'graph-client', '0.0.12'
  spec.add_dependency 'auth-client', '0.0.16'
  spec.add_dependency 'devcenter-client', '0.0.4'
  spec.add_dependency 'playercenter-client', '0.0.4'
end
