# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)
require 'uc3_citation/version'

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

  spec.add_runtime_dependency('logger', '~> 1.4')

  # BibTeX-Ruby is the Rubyist's swiss-army-knife for all things BibTeX.
  # https://github.com/inukshuk/bibtex-ruby
  spec.add_runtime_dependency('bibtex-ruby', '~> 6.0')

  # CSL-Ruby provides a Ruby parser and a comprehensive API for the
  # Citation Style Language (CSL), an XML-based format to describe the formatting
  # of citations, notes and bibliographies. (https://github.com/inukshuk/csl-ruby)
  spec.add_runtime_dependency('csl-styles', '~> 1.0')

  # CiteProc-Ruby is a Citation Style Language (CSL) 1.0.1 cite processor written
  # in pure Ruby. (https://github.com/inukshuk/citeproc-ruby)
  spec.add_runtime_dependency('citeproc-ruby', '~> 1.1')

  # Requirements for running RSpec
  spec.add_development_dependency('byebug', '11.1.3')
  spec.add_development_dependency('rspec', '3.9.0')
  spec.add_development_dependency('rubocop', '0.88.0')
end
