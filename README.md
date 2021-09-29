uc3-citation
===============

A library that generates a citation for the specified DOI.

This service makes a request to the DOI registrar and asks for the BibTeX version of the DOI's metadata.

If BibTeX metadata is received the service will use the CiteProc gem to build a citation that follows the Chicago Author-Date format (CiteProc uses [Citation Style Language (CSL)](https://citationstyles.org/) to build the citation). The citation is in HTML format.

You can override the default Chicago style by specifying one from the list of CSLs located in the following repository: https://github.com/citation-style-language/styles-distribution/tree/f8524f9b9df60e94e98f824f242a1fb27cc9fc59
For example `Uc3::Citation.fetch(doi: '10.1234/article.ef34', work_type: 'article', style: 'apa')`

## Installation -

Run `gem install uc3-citation`

Or add it to your project's Gemfile and then run bundle install:
`gem 'uc3-citation'`

## Basic Usage -

Once installed you can then use the service like this:
```ruby
  class YourClass
    include Uc3Citation

    article = fetch_citation(
      doi: 'https://doi.org/10.3897/BDJ.9.e67426',
      work_type: 'dataset'
    )

    p article
    # Will display:
    #
    # Reboleira, Ana Sofia, and Rita Eus\'ebio. 2021. “Cave-Adapted Beetles from Continental
    # Portugal.” [Dataset]. Biodiversity Data Journal 9 (August).
    # https://doi.org/10.3897/BDJ.9.e67426.
  end
```

The `fetch_citation` method accepts the following arguments:
- **doi**: The fully qualified URl or the DOI as a string. (e.g. 'https://doi.org/10.3897/BDJ.9.e67426', 'doi:10.3897/BDJ.9.e67426', or '10.3897/BDJ.9.e67426'). In the case where you are only passing the DOI, it will prepend 'https://doi.org/' when trying to acquire the citation. If the DOI is not resolvable from that domain then you will need to send the full URL
- **work_type**: Default is nil. If present, the value you specify will be added to the citation after the title to provide context as to what type of work the DOI represents. See example above.
- **style**: Default is 'chicago-author-date'. You can specify [any of the CSL defined in this list](https://github.com/citation-style-language/styles-distribution/tree/f8524f9b9df60e94e98f824f242a1fb27cc9fc59)
- **debug**: Default is false. If true it will log the results of the request for the BibTeX metadata from the DOI registrar and the result of the citation generation from the CitProc library

Although unlikely, since citations are acquired from external sources, it is a good idea to wrap the citation in a sanitization method when displaying on a web page to prevent any malicious HTML. For example in a Rails view you can use: `sanitize(article)`

You should consider the fact that this gem calls out to external systems when incorporating it into your projects. For example adding to a Model or Controller method in Rails can potentially cause slow response times. You may want to use ActiveJob or at the very least an `after_save` callback to prevent it from slowing down the Rails thread that is handling the Request-Response cycle.

## Troubleshooting

If you are not receiving a citation for a specific DOI and you believe you should, you should:

1. Verify that the DOI is able to produce the BibTeX format. For exmaple: `curl -vLH 'Accept: application/x-bibtex' https://doi.org/10.3897/BDJ.9.e67426`
2. Specify `debug: true` when calling `fetch_citation` which will output the BibTex and CiteProc responses to your log file.

NOTE that errors encountered by the gem are always written to the logs regardless of the `:debug` flag specification
