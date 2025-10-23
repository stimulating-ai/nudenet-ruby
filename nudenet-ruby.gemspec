# frozen_string_literal: true

require_relative "lib/nudenet/version"

Gem::Specification.new do |spec|
  spec.name = "nudenet-ruby"
  spec.version = NudeNet::VERSION
  spec.authors = ["Your Name"]
  spec.email = ["your.email@example.com"]

  spec.summary = "AI-powered nudity detection for Ruby"
  spec.description = "A neural network powered library that detects nudity in images. Uses YOLOv8 ONNX models for fast, accurate detection of NSFW content. Ruby implementation of NudeNet."
  spec.homepage = "https://github.com/stimulating-ai/nudenet-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir[
    "lib/**/*.rb",
    "models/**/*",
    "sorbet/**/*",
    "sig/**/*",
    "LICENSE.md",
    "README.md"
  ]
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "ruby-vips", "~> 2.2"
  spec.add_dependency "numo-narray", "~> 0.9.2"
  spec.add_dependency "onnxruntime", "~> 0.10.1"
  spec.add_dependency "sorbet-runtime", "~> 0.5"

  # Development dependencies
  spec.add_development_dependency "rake", "~> 13.2"
  spec.add_development_dependency "rspec", "~> 3.13"
  spec.add_development_dependency "sorbet", "~> 0.5"
  spec.add_development_dependency "tapioca", "~> 0.16"
end
