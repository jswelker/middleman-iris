require 'spec_helper'
app = @app

describe 'Middleman::Iris' do
  let(:app) do
    app
  end
  let(:resource) { app.sitemap.find_resource_by_path('collections/test_collection/item2/index.html')}
  let(:child_file) { app.sitemap.find_resource_by_path('collections/test_collection/item2/some_pdf.pdf') }
  let(:root) { Middleman::Sitemap::Resource.site_root(app) }

  before(:all) do
    FileUtils.rm_rf(app.sitemap.find_resource_by_path('collections/test_collection/item2/index.html').metadata_directory_path)
  end

  describe 'ResourceProcessingExtensions' do

    it 'ignores specified files and directories' do
      expect(app.sitemap.resources.select{|r| r.filename == '.keep' && !r.ignored?}.length).to eq 0
      expect(app.sitemap.resources.select{|r| r.dirname == '.originals' && !r.ignored?}.length).to eq 0
      expect(app.sitemap.resources.select{|r| r.filename == 'some_ignored_page.html.md.erb' && !r.ignored?}.length).to eq 0
    end


    it 'generates and reads file history' do
      Middleman::Sitemap::Resource.generate_history(app.sitemap.resources)
      expect(resource.file_history.values.last['checksum']).to eq resource.current_checksum
      expect(resource.file_history.values.last['timestamp'].to_i).to be > Time.now.to_i - 60
    end


    it 'generates and reads file text' do
      Middleman::Sitemap::Resource.generate_text(app.sitemap.resources)
      expect(child_file.text).to include('U.S. Individual Income Tax Return')
      expect(app.sitemap.find_resource_by_path('collections/test_collection/item2/some_excel_sheets.xlsx').text).to include('This is A1')
      expect(app.sitemap.find_resource_by_path('collections/test_collection/item2/some_word_doc.docx').text).to include('This is another paragraph.')
      expect(app.sitemap.find_resource_by_path('collections/test_collection/item2/some_powerpoint.pptx').text).to include('These pretzels are making me thirsty!')
      expect(resource.text).to eq nil
    end


    it 'generates and retrieves thumbnails' do
      FileUtils.rm_rf("#{root.dirname}/images")
      Middleman::Sitemap::Resource.generate_thumbnails([resource, resource.children_in_same_directory].flatten)
      expect(child_file.thumbnail?).to be true
      expect(resource.thumbnail?).to be false
      expect(child_file.child_thumbnail?).to be false
      expect(resource.child_thumbnail?).to be true
      expect(resource.child_thumbnail_url).to eq 'http://localhost:4567/images/thumbnails/collections/test_collection/item2/some_excel_sheets.xlsx.png'
      expect(child_file.thumbnail_url).to_not be_nil
      expect(Middleman::Sitemap::Resource.file_size(child_file.thumbnail_path)).to eq '106.58 KB'
      expect(Middleman::Sitemap::Resource.file_size("#{root.dirname}/images/thumbnails/collections/test_collection/item2/some_excel_sheets.xlsx.png")).to eq '698 B'
      expect(Middleman::Sitemap::Resource.file_size("#{root.dirname}/images/thumbnails/collections/test_collection/item2/some_word_doc.docx.png")).to eq '2.59 KB'
      expect(Middleman::Sitemap::Resource.file_size("#{root.dirname}/images/thumbnails/collections/test_collection/item2/some_powerpoint.pptx.png")).to eq '4.13 KB'
      expect(child_file.thumbnail_path).to eq "#{root.dirname}/images/thumbnails/collections/test_collection/item2/some_pdf.pdf.png"
    end


    it 'generates the search index' do
      Middleman::Sitemap::Resource.generate_index(app)
      expect(resource.index_scopes[resource.parent.page_id]).to eq 'Test Collection'
      expect(child_file.best_index_rules[:properties]).to match_array(%w(schema:name schema:description schema:author schema:keywords schema:copyrightYear bf:title bf:contribution bf:subject))
      expect(child_file.best_index_rules[:file_text]).to eq 200
      expect(child_file.index_text).to include('Individual Income Tax Return')
      index_string = File.read("#{root.dirname}/.metadata/index.json")
      index_hash = JSON.parse(index_string)
      id_token = index_hash["tokens"].select{|k,v|v=='id'}.keys.first
      title_token = index_hash["tokens"].select{|k,v|v=='bt'}.keys.first
      description_token = index_hash["tokens"].select{|k,v|v=='schema:description'}.keys.first
      expect(index_string).to include(child_file.index_text)
      expect(index_hash["docs"].select{|r| r[id_token] == resource.uri}.length).to eq 1
      expect(index_hash["docs"].select{|r| r[id_token] == resource.uri}.first[title_token]).to eq resource.best_title
      expect(index_hash["docs"].select{|r| r[id_token] == resource.uri}.first[description_token]).to eq 'This is a test item with many different types of files.'
    end


    it 'generates an rss feed' do
      Middleman::Sitemap::Resource.generate_rss(app)
      doc = Nokogiri::XML(File.read("#{root.dirname}/.metadata/index.atom"))
      expect(doc.css('feed > title').text).to eq ' - RSS Feed'
      expect(doc.css('entry').first.css('title').text).to eq 'Test Item 1'
      expect(doc.css('entry').first.css('id').text).to eq 'http://purl.org/someuri'
    end


    it 'generates an oai static metadata repository' do
      Middleman::Sitemap::Resource.generate_oai(app)
      doc = Nokogiri::XML(File.read("#{root.dirname}/.metadata/oai-pmh.xml"))
      expect(doc.at_css('Identify oai|granularity').text).to eq 'YYYY-MM-DDThh:mm:ssZ'
      expect(doc.at_css('ListMetadataFormats oai|metadataNamespace').text).to eq'http://www.openarchives.org/OAI/2.0/oai_dc/'
      expect(doc.at_css('ListRecords oai|record oai|identifier').text).to eq 'http://purl.org/someuri'
      expect(doc.at_css('ListRecords oai|record oai|dc').children.select{|c| c.name == 'title'}.first.text).to eq 'Test Item 1'
      expect(doc.at_css('ListRecords oai|record oai|dc').children.select{|c| c.name == 'language'}.first.text).to eq 'en_US'
      expect(doc.at_css('ListRecords oai|record oai|dc').children.select{|c| c.name == 'creator'}.first.text).to eq 'Welker, Joshua S.'
    end


    it 'generates rdf metadata files' do
      Middleman::Sitemap::Resource.generate_rdf(app)
      expect(JSON.parse(File.read("#{root.metadata_directory_path}/index.jsonld"))['@graph'][2]['@id']).to eq JSON.parse(resource.to_jsonld)['@id']
      expect(File.read("#{root.metadata_directory_path}/index.nt")).to include('<http://purl.org/someuri2> <http://schema.org/name> "Test Item 2" .')
      expect(File.read("#{root.metadata_directory_path}/index.ttl")).to match(/<http:\/\/purl.org\/someuri2> a (schema:Article|schema:IndividualProduct)/)
    end


    it 'generates MARC records' do
      Middleman::Sitemap::Resource.generate_marc(app)
      doc = File.open("#{root.dirname}/.metadata/index.mrc.xml"){ |f| Nokogiri::XML(f) }
      expect(doc.at_css('record leader').text).to eq '00438npma 22001688u 4500'
      expect(doc.css('record')[1].at_css('datafield').text.strip).to eq 'Test Item 2'
      expect(File.readlines("#{root.metadata_directory_path}/index.mrc")[0].split(' ').join(' ')).to eq "00438npma 22001698u 4500245001600000520006000016024002800076046003000104260001500134546001000149774001900159720002200178542000900200653002400209300001100233001002400244\u001E00\u001FaTest Item 1\u001E  \u001FaThis is a test item with many different types of files.\u001E8 \u001Fahttp://purl.org/someuri\u001E
\u001Fj2018-03-13 11:03:43 -0500\u001E  \u001Fc2018-01-24\u001E  \u001Faen_US\u001E0 \u001Fnsome_audio.mp3\u001E  \u001FaWelker, Joshua S.\u001E  \u001Fg2018\u001E  \u001FaJuvenile Literature\u001E  \u001Fa1200 g\u001Ehttp://purl.org/someuri\u001E\u001D\r\n".split(' ').join(' ')
    end


  end
end
