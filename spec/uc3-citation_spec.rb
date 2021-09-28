# frozen_string_literal: true

require 'ostruct'
require 'spec_helper.rb'

# rubocop:disable Metrics/BlockLength
RSpec.describe 'uc3-citation', type: :feature do
  include Uc3Citation

  before(:each) do
    @doi = '10.1234/cdl.12345'
    @uri = "https://doi.org/#{@doi}"
    @headers = { 'Accept': 'application/x-bibtex' }
    @title = 'Arctic river dissolved and biogenic silicon exports'
    @publisher = 'Dryad'

    @bibtex = "@misc{#{@uri},
      doi = {#{@doi}},
      url = {http://example.org/datasets/doi:#{@doi}},
      author = {Doe, Jane},
      keywords = {rivers, biogenic silica, dissolved silica, Permafrost},
      language = {en},
      title = {#{@title}},
      publisher = {#{@publisher}},
      year = {2020},
      copyright = {Creative Commons Zero v1.0 Universal}
    }"
  end

  describe 'fetch_citation(doi:, work_type:, style:, debug:)' do
    it 'returns nil if :doi is not specified' do
      expect(send(:fetch_citation, doi: nil)).to eql(nil)
      expect(send(:fetch_citation, doi: '')).to eql(nil)
    end
    it "returns the citation" do
      allow(self).to receive(:doi_to_uri).and_return(@uri)
      stub_request(:get, @uri).with(headers: @headers)
                              .to_return(status: 200, body: @bibtex, headers: {})
      allow(self).to receive(:bibtex_to_citation).and_return('foo')
      expect(send(:fetch_citation, doi: @doi)).to eql('foo')
    end
    it 'handles errors' do
      allow(self).to receive(:doi_to_uri).and_return(@uri)
      stub_request(:get, @uri).with(headers: @headers)
                              .to_raise(URI::InvalidURIError.new('foo'))
      expect(send(:fetch_citation, doi: @doi)).to eql(nil)
    end
  end

  context 'private methods' do
    describe 'doi_to_uri(doi:)' do
      it 'returns nil if :doi is not specified' do
        expect(send(:doi_to_uri, doi: nil)).to eql(nil)
        expect(send(:doi_to_uri, doi: '')).to eql(nil)
      end
      it 'returns the :doi as-is if it starts with "http"' do
        http = 'http://foo.bar'
        https = 'https://foo.bar'
        expect(send(:doi_to_uri, doi: http)).to eql(http)
        expect(send(:doi_to_uri, doi: https)).to eql(https)
      end
      it 'prepends the value of DEFAULT_DOI_URL to :doi' do
        doi = 'doi:10.1234/abcd.56ef'
        id = '10.1234/abcd.56ef'
        expect(send(:doi_to_uri, doi: doi)).to eql("#{Uc3Citation::DEFAULT_DOI_URL}/#{id}")
        expect(send(:doi_to_uri, doi: id)).to eql("#{Uc3Citation::DEFAULT_DOI_URL}/#{id}")
      end
    end

    describe 'determine_work_type(bibtex:)' do
      it 'returns an empty string if :bibtex is not specified or does not contain data' do
        expect(send(:determine_work_type, bibtex: nil)).to eql('')
        bibtex = OpenStruct.new(data: nil)
        expect(send(:determine_work_type, bibtex: bibtex)).to eql('')
        bibtex = OpenStruct.new(data: [])
        expect(send(:determine_work_type, bibtex: bibtex)).to eql('')
      end
      it 'returns "article" if the bibtex data includes :journal info' do
        bibtex = OpenStruct.new(data: [OpenStruct.new(journal: 'Foo')])
        expect(send(:determine_work_type, bibtex: bibtex)).to eql('article')
      end
      it 'returns an empty string if it could not dtermine a work_type' do
        bibtex = OpenStruct.new(data: [OpenStruct.new(title: 'Foo')])
        expect(send(:determine_work_type, bibtex: bibtex)).to eql('')
      end
    end

    describe 'fetch_bibtex(uri:)' do
      it 'returns nil if :uri is not specified' do
        expect(send(:fetch_bibtex, uri: nil)).to eql(nil)
        expect(send(:fetch_bibtex, uri: '')).to eql(nil)
      end
      it 'calls itself recursively if a redirect was received' do
        resp_headers = { 'Location': "#{@uri}/foo" }
        # stub a response so that it redirects
        stub_request(:get, @uri).with(headers: @headers)
                                .to_return(status: 302, body: '', headers: resp_headers)
        # Stub the response from our faux redirect
        stub_request(:get, resp_headers[:Location]).to_return(
          status: 200, body: "", headers: {}
        )
        expect(send(:fetch_bibtex, uri: @uri).code).to eql(200)
      end
      it 'returns the Response' do
        # stub a response
        stub_request(:get, @uri).with(headers: @headers)
                                .to_return(status: 200, body: @bibtex, headers: {})
        response = send(:fetch_bibtex, uri: @uri)
        expect(response.class.name).to eql('HTTParty::Response')
        expect(response.code).to eql(200)
        expect(response.body).to eql(@bibtex)
      end
    end

    describe 'bibtex_to_citation(uri:, work_type:, bibtex:, style:)' do
      before(:each) do
        @args = {
          uri: @uri,
          work_type: 'dataset',
          bibtex: BibTeX.parse(@bibtex),
          style: 'chicago-author-date'
        }
      end
      it 'returns nil if :uri is not specified' do
        @args[:uri] = nil
        expect(send(:bibtex_to_citation, @args)).to eql(nil)
        @args[:uri] = ''
        expect(send(:bibtex_to_citation, @args)).to eql(nil)
      end
      it 'returns an empty string if :bibtex is not specified or does not contain data' do
        @args[:bibtex] = nil
        expect(send(:bibtex_to_citation, @args)).to eql(nil)
        @args[:bibtex] = OpenStruct.new(data: nil)
        expect(send(:bibtex_to_citation, @args)).to eql(nil)
        @args[:bibtex] = OpenStruct.new(data: [])
        expect(send(:bibtex_to_citation, @args)).to eql(nil)
      end
      it 'returns nil if CiteProc has an issue with the BibTeX' do
        allow_any_instance_of(CiteProc::Processor).to receive(:render).and_return([])
        expect(send(:bibtex_to_citation, @args)).to eql(nil)
      end
      it 'returns the citation for the default :chicago-author-date style' do
        citation = send(:bibtex_to_citation, @args)
        expect(citation.is_a?(String)).to eql(true)
        expect(citation.include?(@doi)).to eql(true)
        expect(citation.include?(@uri)).to eql(true)
        expect(citation.downcase.include?(@title.downcase)).to eql(true)
        expect(citation.downcase.include?(@publisher.downcase)).to eql(true)
        expect(citation.downcase.include?("[#{@args[:work_type].downcase}].")).to eql(true)
      end
      it 'returns the citation for the :apa style' do
        @args[:style] = 'apa'
        citation = send(:bibtex_to_citation, @args)
        expect(citation.is_a?(String)).to eql(true)
        expect(citation.include?(@doi)).to eql(true)
        expect(citation.include?(@uri)).to eql(true)
        expect(citation.downcase.include?(@title.downcase)).to eql(true)
        expect(citation.downcase.include?(@publisher.downcase)).to eql(true)
        expect(citation.downcase.include?("[#{@args[:work_type].downcase}].")).to eql(true)
      end
      it 'replaces "{\Textendash}" correctly' do
        @bibtex = @bibtex.gsub(@title, "#{@title}{\\textendash}foo")
        @args[:bibtex] = BibTeX.parse(@bibtex)
        citation = send(:bibtex_to_citation, @args)
        expect(citation.downcase.include?("#{@title.downcase}-foo")).to eql(true)
      end
      it 'replaces "{" and "}" correctly' do
        @bibtex = @bibtex.gsub(@title, "#{@title} {FOO}")
        @args[:bibtex] = BibTeX.parse(@bibtex)
        citation = send(:bibtex_to_citation, @args)
        expect(citation.downcase.include?("#{@title.downcase} foo")).to eql(true)
      end
      it "includes the DOI as an HTML link" do
        citation = send(:bibtex_to_citation, @args)
        expect(citation.downcase.include?("href=\"#{@uri}\"")).to eql(true)
      end
    end
  end
end
