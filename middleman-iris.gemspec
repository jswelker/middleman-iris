# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'middleman-iris/version'

Gem::Specification.new do |spec|
  spec.name          = "middleman-iris"
  spec.version       = Middleman::Iris::VERSION
  spec.authors       = ["Joshua Welker"]
  spec.email         = ["welker@ucmo.edu"]

  spec.summary       = %q{This is a short description.}
  spec.description   = %q{This is a longer description.}
  spec.homepage      = "http://library.ucmo.edu"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency("middleman-core", "~> 4.2")
  spec.add_runtime_dependency("middleman-vcs-time", "~> 0.0")
  spec.add_runtime_dependency("rdf", "~> 3.0")
  spec.add_runtime_dependency("rdf-rdfxml", "~> 2.2")
  spec.add_runtime_dependency("rdf-turtle", "~> 3.0")
  spec.add_runtime_dependency("json-ld", "~> 2.2")
  spec.add_runtime_dependency("marc", "~> 1.0")
  spec.add_runtime_dependency("mime-types", "~> 3.1")
  spec.add_runtime_dependency("rmagick", "~> 2.16")
  spec.add_runtime_dependency("pdf-reader", "~> 2.0")
  spec.add_runtime_dependency("roo", "~> 2.7")
  spec.add_runtime_dependency("nokogiri", "~> 1.8")
  spec.add_runtime_dependency("object_flatten", "~> 0.1")
  spec.add_runtime_dependency("httparty", "~> 0.15")
  spec.add_runtime_dependency("kramdown", "~> 1.16.2")

  spec.add_development_dependency("middleman-cli", "~> 4.2")
  spec.add_development_dependency("bundler", "~> 1.14")

end
