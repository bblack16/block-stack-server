
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "block_stack/server/version"

Gem::Specification.new do |spec|
  spec.name          = "block_stack_server"
  spec.version       = BlockStack::Server::VERSION
  spec.authors       = ["Brandon Black"]
  spec.email         = ["d2sm10@hotmail.com"]

  spec.summary       = %q{BlockStack Server provides a simple and powerful REST API framework, using Sinatra.}
  spec.description   = %q{The REST API functionality for the BlockStack suite.}
  spec.homepage      = "https://github.com/bblack16/block-stack-server"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'sinatra', '~> 2.0'
  spec.add_runtime_dependency 'block_stack_util', '~> 1.0'
  spec.add_runtime_dependency 'block_stack_model', '~> 1.0'
  spec.add_runtime_dependency 'block_stack_query', '~> 1.0'
  spec.add_runtime_dependency 'gyoku', '~> 1.3'
  spec.add_runtime_dependency 'task_vault', '~> 1.0'
  spec.add_runtime_dependency 'harmoni', '~> 0.1'

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
