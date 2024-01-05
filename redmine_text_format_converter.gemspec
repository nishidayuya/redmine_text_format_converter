# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'redmine_text_format_converter/version'

Gem::Specification.new do |spec|
  spec.name          = "redmine_text_format_converter"
  spec.version       = RedmineTextFormatConverter::VERSION
  spec.authors       = ["Yuya.Nishida."]
  spec.email         = ["yuya@j96.org"]
  spec.summary       = "A Redmine plugin to convert text format from Textile to Markdown."
  spec.homepage      = "https://github.com/nishidayuya/redmine_text_format_converter"
  spec.license       = "X11"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "progressbar", "~> 0.21.0"
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
end
