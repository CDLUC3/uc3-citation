# frozen_string_literal: true

require 'bibtex'
require 'citeproc'
require 'csl/styles'

# This service provides an interface to Datacite API.
module Uc3Citation

  DEFAULT_DOI_URL = 'https://doi.org'.freeze

  # Create a new DOI
  # rubocop:disable Metrics/CyclomaticComplexity
  def fetch_citation(doi:, work_type: 'dataset', style: 'chicago-author-date')
    return nil unless doi.present?

    uri = doi_to_uri(id: doi)
    resp = fetch_bibtex(uri: uri)
    return nil unless resp.present? && resp.code == 200

    bibtex = BibTeX.parse(resp.body)

    build_citation(uri: uri, work_type: work_type, bibtex: bibtex, style: style)
  rescue JSON::ParserError => e
    log_error(method: 'Uc3::Citation fetch JSON parse error', error: e)
    nil
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  private

  # Will convert 'doi:10.1234/abcdefg' to 'http://doi.org/10.1234/abcdefg'
  def doi_to_uri(id:)
    return nil unless id.present?

    id.start_with?('http') ? id : "#{api_base_url}/#{id.gsub('doi:', '')}"
  end

  # Recursively call the URI for application/x-bibtex
  def fetch_bibtex(uri:)
    return nil unless uri.present?

    # Cannot use underlying Base Service here because the Accept seems to
    # be lost after multiple redirects
    resp = HTTParty.get(uri, headers: { 'Accept': 'application/x-bibtex' },
                              follow_redirects: false)
    return resp unless resp.headers['location'].present?

    fetch_bibtex(uri: resp.headers['location'])
  end

  # Convert the BibTeX item to a citation
  def build_citation(uri:, work_type:, bibtex:, style:)
    return nil unless uri.present? && bibtex.data.first.id.present?

    cp = CiteProc::Processor.new(style: style, format: 'html')
    cp.import(bibtex.to_citeproc)
    citation = cp.render(:bibliography, id: bibtex.data.first.id)
    return nil unless citation.present? && citation.any?

    # The CiteProc renderer has trouble with some things so fix them here
    #
    #   - It has a '{textendash}' sometimes because it cannot render the correct char
    #   - For some reason words in all caps in the title get wrapped in curl brackets
    #   - We want to add the work type after the title. e.g. `[Dataset].`
    #
    citation = citation.first.gsub(/{\\Textendash}/i, '-')
                              .gsub('{', '').gsub('}', '')
                              .gsub(/\.”\s+/, "\.” [#{id.work_type.humanize}]. ")

    # Convert the URL into a link. Ensure that the trailing period is not a part of
    # the link!
    citation.gsub(URI.regexp) do |url|
      if url.start_with?('http')
        '<a href="%{url}" target="_blank">%{url}</a>.' % {
          url: url.ends_with?('.') ? url[0..url.length - 2] : url
        }
      else
        url
      end
    end
  end

end
