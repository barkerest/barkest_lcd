# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'barkest_lcd/version'

Gem::Specification.new do |spec|
  spec.name          = "barkest_lcd"
  spec.version       = BarkestLcd::VERSION
  spec.authors       = ["Beau Barker"]
  spec.email         = ["rtecoder@gmail.com"]

  spec.summary       = "Provides a simple interface to LCD displays."
  spec.description   = "This gem was originally created to interface with a PicoLCD 256x64 from www.mini-box.com."
  spec.homepage      = "http://www.barkerest.com/"
  spec.license       = "MIT"


  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'libusb',   '~>0.5.1'
  spec.add_dependency 'hidapi',   '>=0.1.0'


  spec.add_development_dependency 'bundler',    '~> 1.12'
  spec.add_development_dependency 'rake',       '~> 10.0'
end
