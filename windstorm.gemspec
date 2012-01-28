# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "windstorm/version"

Gem::Specification.new do |s|
  s.name        = "windstorm"
  s.version     = Windstorm::VERSION
  s.authors     = ["parrot-studio"]
  s.email       = ["parrot.studio.dev@gmail.com"]
  s.homepage    = "https://github.com/parrot-studio/windstorm"
  s.summary     = %q{Program language paser/executor like BrainF**k}
  s.description = s.summary

  s.rubyforge_project = "windstorm"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
end
