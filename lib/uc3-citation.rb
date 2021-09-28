# frozen_string_literal: true

require 'bibtex'
require 'citeproc'
require 'csl/styles'
require 'httparty'
require 'logger'

# This service provides an interface to Datacite API.
module Uc3Citation

  DEFAULT_DOI_URL = 'https://doi.org'.freeze

  # Create a new DOI
  # rubocop:disable Metrics/CyclomaticComplexity
  def fetch_citation(doi:, work_type: '', style: 'chicago-author-date', debug: false)
    return nil unless doi.is_a?(String) && doi.strip != ''

    # Set the logger
    logger = Object.const_defined?("Rails") ? Rails.logger : Logger.new(STDOUT)

    uri = doi_to_uri(doi: doi.strip)
    logger.debug("Uc3Citation - Fetching BibTeX from: '#{uri}'") if debug
    resp = fetch_bibtex(uri: uri)
    return nil if resp.code != 200

    bibtex = BibTeX.parse(resp.body)
    logger.debug('Uc3Citation - Received BibTeX') if debug
    logger.debug(bibtex.data.inspect) if debug

    work_type = determine_work_type(bibtex: bibtex) if work_type.nil? || work_type.split == ''

    citation = bibtex_to_citation(
      uri: uri,
      work_type: work_type,
      bibtex: bibtex,
      style: style
    )
    logger.debug('Uc3Citation - Citation accquired') if debug
    logger.debug(citation) if debug

    citation
  rescue URI::InvalidURIError => e
    logger.error("Uc3Citation - URI: '#{uri}' - InvalidURIError: #{e.message}")
    nil
  rescue HTTParty::Error => e
    logger.error("Uc3Citation - URI: '#{uri}' - HTTPartyError: #{e.message}")
    logger.error(e&.backtrace)
    nil
  rescue SocketError => e
    logger.error("Uc3Citation - URI: '#{uri}' - CiteProc SocketError: #{e.message}")
    logger.error(bibtex&.inspect)
    logger.error(e&.backtrace)
    nil
  rescue StandardError => e
    logger.error("Uc3Citation - error - #{e.class.name}: #{e.message}")
    logger.error(e&.backtrace)
    nil
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  private

  # Will convert 'doi:10.1234/abcdefg' to 'http://doi.org/10.1234/abcdefg'
  def doi_to_uri(doi:)
    return nil unless doi.is_a?(String) && doi.strip != ''

    doi.start_with?('http') ? doi : "#{DEFAULT_DOI_URL}/#{doi.gsub('doi:', '')}"
  end

  # If no :work_type was specified we can try to derive it from the BibTeX metadata
  def determine_work_type(bibtex:)
    return '' if bibtex.nil? || bibtex.data.nil? || bibtex.data.first.nil?

    return 'article' unless bibtex.data.first.journal.nil?

    ''
  end

  # Recursively call the URI for application/x-bibtex
  def fetch_bibtex(uri:)
    return nil unless uri.is_a?(String) && uri.strip != ''

    # Cannot use underlying Base Service here because the Accept seems to
    # be lost after multiple redirects
    resp = HTTParty.get(uri, headers: { 'Accept': 'application/x-bibtex' },
                              follow_redirects: false)
    return resp if resp.headers['location'].nil?

    fetch_bibtex(uri: resp.headers['location'])
  end

  # Convert the BibTeX item to a citation
  def bibtex_to_citation(uri:, work_type:, bibtex:, style:)
    return nil unless uri.is_a?(String) && uri.strip != ''
    return nil if bibtex.nil? || bibtex.data.nil? || bibtex.data.first.nil?

    cp = CiteProc::Processor.new(style: style, format: 'html')
    cp.import(bibtex.to_citeproc)
    citation = cp.render(:bibliography, id: bibtex.data.first.id)
    return nil unless citation.is_a?(Array) && citation.any?

    # The CiteProc renderer has trouble with some things so fix them here
    #
    #   - It has a '{textendash}' sometimes because it cannot render the correct char
    #   - For some reason words in all caps in the title get wrapped in curl brackets
    #   - We want to add the work type after the title. e.g. `[Dataset].`
    #
    citation = citation.first.gsub(/{\\Textendash}/i, '-')
                              .gsub('{', '').gsub('}', '')

    unless work_type.nil? || work_type.strip == ''
      # This supports the :apa and :chicago-author-date styles
      citation = citation.gsub(/\.”\s+/, "\.” [#{work_type.gsub('_', ' ').capitalize}]. ")
                         .gsub(/<\/i>\.\s+/, "<\/i>\. [#{work_type.gsub('_', ' ').capitalize}]. ")
    end

    # Convert the URL into a link. Ensure that the trailing period is not a part of
    # the link!
    citation.gsub(URI.regexp) do |url|
      if url.start_with?('http')
        '<a href="%{url}" target="_blank">%{url}</a>.' % {
          url: url.end_with?('.') ? uri : "#{uri}."
        }
      else
        url
      end
    end
  end

end
