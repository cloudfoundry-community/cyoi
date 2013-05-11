# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cyoi/version'

Gem::Specification.new do |spec|
  spec.name          = "cyoi"
  spec.version       = Cyoi::VERSION
  spec.authors       = ["Dr Nic Williams"]
  spec.email         = ["drnicwilliams@gmail.com"]
  spec.description   = "A library to ask an end-user to choose an infrastructure (AWS, OpenStack, etc), region, and login credentials."
  spec.summary       = <<-README
A library to ask an end-user to choose an infrastructure (AWS, OpenStack, etc), region, and login credentials.

This library was extracted from [inception-server](https://github.com/drnic/inception-server) for reuse by [bosh-bootstrap](https://github.com/StarkAndWayne/bosh-bootstrap). It might also be useful to your own CLI applications that need to ask a user to give you their infrastructure credentials/region so your application can control their infrastructure (say via [fog](http://fog.io)).
README
  spec.homepage      = "https://github.com/drnic/cyoi"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
