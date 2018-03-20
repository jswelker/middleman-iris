require 'spec_helper'
app = @app

describe 'Middleman::Iris' do
  let(:app) do
    app
  end
  let(:resource) { app.sitemap.find_resource_by_path('collections/test_collection/item1/index.html')}
  let(:child_file) { app.sitemap.find_resource_by_path('collections/test_collection/item1/some_pdf.pdf') }
  let(:root) { Middleman::Sitemap::Resource.site_root(app) }
  let(:reports_directory) { "#{app.root}/#{app.extensions[:iris].options[:reports_directory]}" }

  before(:all) do
    FileUtils.rm_rf("#{app.root}/#{app.extensions[:iris].options[:reports_directory]}")
  end

  describe 'ResourceValidatorExtensions' do

    it 'validates missing properties' do
      report_hash = Middleman::Sitemap::Resource.validate_missing_properties(app, ['schema:sku', 'schema:copyrightYear'], nil, true, true)
      properties_file = Dir.glob("#{reports_directory}/missing_properties_*").first
      expect(report_hash[child_file.page_id]).to match_array(['schema:copyrightYear', 'schema:sku'])
      expect(File.read(properties_file)).to include("#{child_file.page_id},schema:sku")
      expect(report_hash[resource.page_id]).to match_array([])
      expect(File.read(properties_file)).to_not include("#{resource.page_id},")
    end


    it 'validates duplicate uris' do
      report_hash = Middleman::Sitemap::Resource.validate_duplicate_uris(app)
      dupes_file = Dir.glob("#{reports_directory}/duplicate_uris_*").first
      expect(report_hash[resource.page_id]).to match_array(['collections/test_collection/dupe_uri/index'])
      expect(File.read(dupes_file)).to include("#{resource.page_id},collections/test_collection/dupe_uri/index")
      expect(report_hash[child_file.page_id]).to match_array([])
      expect(File.read(dupes_file)).to_not include("#{child_file.page_id},")
    end


    it 'validates URIs with HTTP errors' do
      report_hash = Middleman::Sitemap::Resource.validate_http_error_uris(app)
      report_file = Dir.glob("#{reports_directory}/http_error_uris_*").first
      expect(report_hash['http://id.loc.gov/authorities/subjects/sh99001674.html'][:code]).to eq 200
      expect(report_hash['http://purl.org/someuri'][:code]).to eq 404
      expect(File.read(report_file)).to include('http://id.loc.gov/authorities/subjects/sh99001674.html,200,')
    end


  end
end
