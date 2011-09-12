# -*- encoding: utf-8 -*-
require File.expand_path('../lib/pub78/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Nat Budin"]
  gem.email         = ["natbudin@gmail.com"]
  gem.description   = %q{Parser for the IRS Publication 78 data file, with the capability to automatically download from irs.gov}
  gem.summary       = %q{Handles the US Internal Revenue Service's list of tax-exempt organizations}
  gem.homepage      = ""

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "pub78"
  gem.require_paths = ["lib"]
  gem.version       = Pub78::VERSION
end
