# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)
require 'uc3-citation/version'

Gem::Specification.new do |spec|
  spec.name        = 'uc3-citation'
  spec.version     = Uc3Citation::VERSION
  spec.platform    = Gem::Platform::RUBY
  spec.authors     = ['Brian Riley']
  spec.email       = ['brian.riley@ucop.edu']

  spec.summary     = 'UC3 - Citation Service'
  spec.description = 'Send this service a DOI and receive back a citation'
  spec.homepage    = 'https://github.com/CDLUC3/uc3-citation'
  spec.license     = 'MIT'

  spec.files         = Dir['lib/**/*'] + %w[README.md]
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.4'

  # BibTeX-Ruby is the Rubyist's swiss-army-knife for all things BibTeX.
  # https://github.com/inukshuk/bibtex-ruby
  spec.add_runtime_dependency('bibtex-ruby', '~> 6.0')

  # CiteProc-Ruby is a Citation Style Language (CSL) 1.0.1 cite processor written
  # in pure Ruby. (https://github.com/inukshuk/citeproc-ruby)
  spec.add_runtime_dependency('citeproc-ruby', '~> 1.1')

  # CSL-Ruby provides a Ruby parser and a comprehensive API for the
  # Citation Style Language (CSL), an XML-based format to describe the formatting
  # of citations, notes and bibliographies. (https://github.com/inukshuk/csl-ruby)
  spec.add_runtime_dependency('csl-styles', '~> 1.0')

  # Makes http fun again! Wrapper to simplify the native Net::HTTP libraries
  spec.add_runtime_dependency('httparty', '~> 0.19')

  # Logger is a simple but powerful logging utility to output messages in your Ruby program.
  spec.add_runtime_dependency('logger', '~> 1.4')

  # =========================
  # = DEV/TEST Dependencies =
  # =========================

  # Byebug is a Ruby debugger.
  spec.add_development_dependency('byebug', '~> 11.1')

  # RSpec is a computer domain-specific language testing tool written in programming
  # language Ruby to test Ruby code. It is a behavior-driven development framework
  # which is extensively used in production applications.
  spec.add_development_dependency('rspec', '~> 3.10')

  # RuboCop is a Ruby code style checker (linter) and formatter based on the
  # community-driven Ruby Style Guide.
  spec.add_development_dependency('rubocop', '~> 1.21')

  # Library for stubbing HTTP requests in Ruby.
  # (http://github.com/bblimke/webmock)
  spec.add_development_dependency('webmock', '~> 3.14')
end
