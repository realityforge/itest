# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name               = %q{itest}
  s.version            = '1.0'
  s.platform           = Gem::Platform::RUBY

  s.authors            = ['Peter Donald']
  s.email              = %q{peter@realityforge.org}

  s.homepage           = %q{https://github.com/realityforge/itest}
  s.summary            = %q{Improved test tasks for ruby tests under rake or Buildr.}
  s.description        = %q{Improved test tasks for ruby tests under rake or Buildr.}

  s.rubyforge_project  = %q{itest}

  s.files              = `git ls-files`.split("\n")
  s.test_files         = `git ls-files -- {spec}/*`.split("\n")
  s.executables        = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.default_executable = []
  s.require_paths      = %w(lib)

  s.has_rdoc           = false
  s.rdoc_options       = %w(--line-numbers --inline-source --title dbt)

  s.add_development_dependency(%q<minitest>, ['= 5.0.2'])
  s.add_development_dependency(%q<mocha>, ['= 0.14.0'])
end
