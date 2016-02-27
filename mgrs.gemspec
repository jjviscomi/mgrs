# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mgrs/version'

Gem::Specification.new do |spec|
  spec.name          = "mgrs"
  spec.version       = MGRS::VERSION
  spec.authors       = ["Joseph J. Viscomi"]
  spec.email         = ["jjviscomi@gmail.com"]

  spec.summary       = %q{Military Grid Reference System Gem, easily work with
    MRGS and convert between lat/long for processing grid based location data.}
  spec.description   = %q{The military grid reference system (MGRS) is the
    geocoordinate standard used by NATO militaries for locating points on the
    earth. The MGRS is derived from the Universal Transverse Mercator (UTM)
    grid system and the universal polar stereographic (UPS) grid system, but
    uses a different labeling convention. The MGRS is used for the entire earth.
    This allows you to use MGRS directly and easily convert between lat/long
    and grid based location data. You can specify how large of gid squares you
    want to use and is ideal for map overlaying, gid concentrations, or grid
    based computing. Grid sizes are availabe from 1m to 10km.
  }
  spec.homepage      = "https://github.com/jjviscomi/mgrs"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
end
