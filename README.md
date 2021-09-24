Rubygem uc3-citation
===============

A library that retrieves an citation for the specified DOI following the Chicago Author-Date standard.

This service makes a request to the DOI registrar and asks for the BibTeX version of the DOI's metadata.

If BibTeX metadata is received the service will use the CiteProc gem to build a citation that follows the Chicago Author-Date format (CiteProc uses [Citation Style Language (CSL)](https://citationstyles.org/) to build the citation). The citation is in HTML format.

You can override the default Chicago style by specifying one from the list of CSLs located in the following repository: https://github.com/citation-style-language/styles-distribution/tree/f8524f9b9df60e94e98f824f242a1fb27cc9fc59
For example `Uc3::Citation.fetch(doi: '10.1234/article.ef34', work_type: 'article', style: 'apa')`

## Basic Usage -

Add the following to your Gemfile and then run bundle install:
`gem 'uc3-citation', git: 'https://github.com/CDLUC3/uc3-citation', branch: 'main''

Once installed you can then use the service like this:
```ruby
  # Send the DOI (fully qualified URL is preferred). If its just a doi,
  # then 'https://doi.org/ will be prepended when trying to acquire the citation
  #
  # The :work_type default is 'dataset'. You can send any value here, it gets appended to
  # the citation after the title. For example sending:
  #   `Uc3::Citation.fetch(
  #      doi: 'https://doi.org/10.1007/s00338-011-0845-0',
  #      work_type: 'article'
  #    )`
  #
  # Results in the following citation:
  #   Leray, M., J. T. Boehm, S. C. Mills, and C. P. Meyer. 2011. “Moorea BIOCODE Barcode
  #   Library as a Tool for Understanding Predator-Prey Interactions: Insights into the
  #   Diet of Common Predatory Coral Reef Fishes.” [Article]. Coral Reefs 31 (2): 383–88.
  #   https://doi.org/10.1007/s00338-011-0845-0
  #
  require 'uc3-citation'

  article = Uc3Citation.fetch(doi: '10.1234/article.ef34', work_type: 'article')
  book = Uc3Citation.fetch(doi: 'https://doi.org/10.1234/book.ef34', work_type: 'book')
  dmp = Uc3Citation.fetch(doi: 'https://dx.doi.org/10.1234/dmp.ef34', work_type: 'output_management_plan')
  dataset = Uc3Citation.fetch(doi: 'doi:10.1234/dataset.ef34', work_type: 'dataset')
  software = Uc3Citation.fetch(doi: '10.1234/software.ef34', work_type: 'software')

  # to display within a view:
  sanitize(software)
```
