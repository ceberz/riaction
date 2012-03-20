# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "riaction/version"

Gem::Specification.new do |s|
  s.name        = "riaction"
  s.version     = Riaction::VERSION
  s.authors     = ["Chris Eberz", "Katie Miller", "Nicholas Audo"]
  s.email       = ["ceberz@elctech.com"]
  s.homepage    = "https://github.com/zortnac/riaction/"
  s.summary     = %q{Wrapper for IActionable's restful API and an "acts-as" style interface for models to behave as profiles and drive game events.}
  s.description = %q{Wrapper for IActionable's restful API and an "acts-as" style interface for models to behave as profiles and drive game events.}

  s.rubyforge_project = "riaction"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib", "spec"]


  s.add_development_dependency "rspec", ">= 2.8"
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "ruby-debug19"
  s.add_development_dependency "yard"
  s.add_development_dependency "redcarpet"
  s.add_development_dependency "activerecord", ">= 3.0.0"
  # s.add_development_dependency "bundler", "~>1.1.1"

  s.add_runtime_dependency "rake"
  s.add_runtime_dependency "activesupport", ">= 3.0.0"
  s.add_runtime_dependency "resque"
  s.add_runtime_dependency "ruby-iactionable", ">= 0.0.2"
end
