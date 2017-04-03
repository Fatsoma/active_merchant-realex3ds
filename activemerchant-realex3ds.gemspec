$LOAD_PATH.push File.expand_path('../lib', __FILE__)

require 'rubygems'
require 'English'

Gem::Specification.new do |s|
  s.platform     = Gem::Platform::RUBY
  s.name         = 'activemerchant-realex3ds'
  s.version      = '1.0.1'
  s.summary      = 'Realex gateway for ActiveMerchant with 3D Secure support'
  s.description  = 'Realex is the leading payment provider for Ireland. The default gateway included in ActiveMerchant does not support 3D Secure. This implementation does, it was sponsored by Ticketsolve, written by David Rice, and released as a gem for the current version of ActiveMerchant by Arne Brasseur.'

  s.authors = ['David Rice', 'Arne Brasseur']
  s.email = 'arne@arnebrasseur.net'
  s.homepage = 'https://github.com/plexus/active_merchant-realex3ds'
  s.rubyforge_project = 'activemerchant-realex3ds'

  s.require_paths    = %w(lib)
  s.files            = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  s.test_files       = `git ls-files -- spec`.split($INPUT_RECORD_SEPARATOR)
  s.extra_rdoc_files = %w(README.md)

  s.license = 'MIT'

  s.add_dependency('activemerchant', '>= 1.34', '< 1.44.0')

  s.add_development_dependency('rake')
  s.add_development_dependency('mocha', '~> 0.13.0')
  s.add_development_dependency('rails', '>= 2.3.14', '< 5.0')
  s.add_development_dependency('equivalent-xml')
  s.add_development_dependency('minitest')
  s.add_development_dependency('money')
  s.add_development_dependency('guard')
  s.add_development_dependency('guard-minitest')
end
