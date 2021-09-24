# frozen_string_literal: true

require 'bibtex'
require 'citeproc'
require 'csl/styles'

# This service provides an interface to Datacite API.
module Uc3Citation

  DEFAULT_DOI_URL = 'https://doi.org'.freeze

  # Create a new DOI
  # rubocop:disable Metrics/CyclomaticComplexity
  def fetch_citation(doi:, work_type: '', style: 'chicago-author-date', debug: false)
    return nil unless doi.present?

    uri = doi_to_uri(doi: doi)
    Rails.logger.debug("Uc3Citation - Fetching BibTeX from: '#{uri}'") if debug
    resp = fetch_bibtex(uri: uri)
    return nil unless resp.present? && resp.code == 200

    bibtex = BibTeX.parse(resp.body)
    Rails.logger.debug('Uc3Citation - Received BibTeX') if debug
    Rails.logger.debug(bibtex.data.inspect) if debug

    citation = build_citation(
      uri: uri,
      work_type: work_type.present? ? work_type : determine_work_type(bibtex: bibtex),
      bibtex: bibtex,
      style: style
    )
    Rails.logger.debug('Uc3Citation - Citation accquired') if debug
    Rails.logger.debug(citation) if debug

    citation
  rescue JSON::ParserError => e
    Rails.logger.error("Uc3Citation - JSON parse error - #{e.message}")
    Rails.logger.error(e&.backtrace)
    nil
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  private

  # Will convert 'doi:10.1234/abcdefg' to 'http://doi.org/10.1234/abcdefg'
  def doi_to_uri(doi:)
    return nil unless doi.present?

    doi.start_with?('http') ? doi : "#{api_base_url}/#{doi.gsub('doi:', '')}"
  end

  def determine_work_type(bibtex:)
    return '' unless bibtex.present? && bibtex.data.first.present?

    return 'article' if bibtex.data.first.journal.present?
    return 'software' if bibtex.data.first.software.present?

    ''
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

    citation = citation.gsub(/\.”\s+/, "\.” [#{work_type.humanize}]. ") if work_type.present?

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
