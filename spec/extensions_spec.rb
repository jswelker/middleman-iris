require 'spec_helper'
app = @app

describe 'Middleman::Iris' do
  let(:app) do
    app
  end
  let(:resource) { app.sitemap.find_resource_by_path('collections/test_collection/item1/index.html')}
  let(:child_file) { app.sitemap.find_resource_by_path('collections/test_collection/item1/some_pdf.pdf') }
  let(:root) { Middleman::Sitemap::Resource.site_root(app) }

  describe 'ResourceHelperExtensions' do
    it 'traverses the sitemap tree and makes relative comparisons between files' do
      # Test iris_resource?
      expect(resource.iris_resource?).to be true

      # Test site_root? and iris_resource?
      expect(root).to_not be_nil
      expect(root.iris_resource?).to be false

      # Test in_collections_dir?
      expect(resource.in_collections_dir?).to be true
      expect(root.in_collections_dir?).to be false

      # Test same_directory?(resource)
      expect(resource.same_directory?(root)).to be false
      expect(resource.same_directory?(child_file)).to be true

      # Test files_in_same_directory
      expect(resource.files_in_same_directory).to include(child_file)
      expect(resource.files_in_same_directory).to_not include(root)

      # Test children_in_same_directory(multiple types)
      expect(resource.children_in_same_directory(:static_file)).to include(child_file)
      expect(resource.children_in_same_directory).to include(child_file)

      # Test descendant_of?(resource)
      expect(resource.descendant_of?(resource.parent)).to be true
      expect(resource.descendant_of?(child_file)).to be false

      # Test collection
      expect(resource.collection.page_id).to eq 'collections/test_collection/index'

      # Test in_metadata_dir?
      expect(resource.in_metadata_dir?).to be false
      expect(app.sitemap.resources.select{|r| r.source_file.include?('/.metadata/')}.first&.in_metadata_dir?).to be true

      # Test breadcrumb_resources
      expect(resource.breadcrumb_resources.map{|r| r.page_id}).to match_array([
        'index',
        'collections/test_collection/index',
        'collections/test_collection/item1/index'
      ])
    end


    it 'provides info about files' do
      # Test resource_file_size
      expect(resource.resource_file_size).to eq '3.01 KB'

      # Test current_checksum
      expect(resource.current_checksum).to_not be_nil

      # Test filename
      expect(resource.filename).to eq 'index.html.md.erb'

      # Test dirname
      expect(resource.dirname).to eq "#{ENV['MM_ROOT']}/source/collections/test_collection/item1"

      # Test dirname_last
      expect(resource.dirname_last).to eq 'item1'
    end


    it 'determines resource type' do
      # Test collection?
      expect(resource.collection?).to be false
      expect(resource.parent.collection?).to be true

      # Test page?
      expect(resource.page?).to be false
      expect(app.sitemap.find_resource_by_path('collections/test_collection/item1/some_page.html').page?).to be true

      # Test static_file?
      expect(resource.static_file?).to be false
      expect(child_file.static_file?).to be true

      # Test img?
      expect(resource.img?).to be false
      expect(app.sitemap.find_resource_by_path('collections/test_collection/item1/some_jpeg_image.jpg').img?).to be true

      # Test pdf?
      expect(resource.pdf?).to be false
      expect(child_file.pdf?).to be true

      # Test spreadsheet?
      expect(resource.spreadsheet?).to be false
      expect(app.sitemap.find_resource_by_path('collections/test_collection/item1/some_excel_sheets.xlsx').spreadsheet?).to be true

      # Test video?
      expect(resource.video?).to be false
      expect(app.sitemap.find_resource_by_path('collections/test_collection/item1/some_video.mp4').video?).to be true

      # Test audio?
      expect(resource.audio?).to be false
      expect(app.sitemap.find_resource_by_path('collections/test_collection/item1/some_audio.mp3').audio?).to be true

      # Test resource_type
      expect(resource.resource_type).to eq 'item'
      expect(resource.parent.resource_type).to eq 'collection'
      expect(child_file.resource_type).to eq 'file'

      # Test icon
      expect(resource.icon).to eq 'fas fa-folder'
      expect(child_file.icon).to eq 'far fa-file-pdf'

    end

    it 'reads YAML front matter' do
      # Test iris_value
      expect(resource.iris_value('permalink')).to eq 'http://purl.org/someuri'

      # Test best_title
      expect(resource.best_title).to eq 'Test Item 1'

      # Test best_description
      expect(resource.best_description).to eq 'This is a test item with many different types of files.'

      # Test best_creator
      expect(resource.best_creator).to eq 'Welker, Joshua S.'

      # Test featured?
      expect(resource.featured?).to be true
      expect(root.featured?).to be false

      # Test position
      expect(resource.position).to be_nil
      expect(child_file.position).to eq 1

      # Test permalink
      expect(resource.permalink).to eq 'http://purl.org/someuri'
      expect(child_file.permalink).to eq 'http://localhost:4567/collections/test_collection/item1/some_pdf.pdf'

      # Test uri
      expect(resource.uri).to eq 'http://purl.org/someuri'
      expect(child_file.uri).to eq 'http://purl.org/someuri#some_pdf.pdf'

      # Test uri_slug
      expect(resource.uri_slug).to be_nil
      expect(child_file.uri_slug).to eq 'some_pdf.pdf'

    end


    it 'locates specific resources and collections' do
      # Test iris_resources
      expect(Middleman::Sitemap::Resource.iris_resources(app).length).to eq 45

      # Test site_root
      expect(Middleman::Sitemap::Resource.site_root(app).page_id).to eq 'index'

      # Test sort_resources
      expect(Middleman::Sitemap::Resource.sort_resources(app.sitemap.resources).first.page_id) == child_file.page_id

      # Test collections
      expect(Middleman::Sitemap::Resource.collections(app).length).to eq 3

      # Test specific_resources
      expect(Middleman::Sitemap::Resource.specific_resources(app, ['index.html', 'collections/test_collection/index.html']).length).to eq 2
      expect(Middleman::Sitemap::Resource.specific_resources(app, ['index', 'collections/test_collection/index']).length).to eq 2

      # Test root_collections
      expect(Middleman::Sitemap::Resource.root_collections(app).first.page_id).to eq 'collections/test_collection/index'

      # Test file_size
      expect(Middleman::Sitemap::Resource.file_size(child_file.source_file)).to eq '188.03 KB'
    end

  end


  describe 'ResourceRdfExtensions' do
    it 'loads and merges data from defaults and templates' do
      # Test metadata_from_parent
      expect(child_file.metadata_from_parent.dig('iris', 'rdf_properties', 'schema:description')).to eq 'This is some PDF file.'

      # Test metadata_from_file
      expect(child_file.metadata_from_file['file_property']).to eq 'this is a value'

      # Test metadata_from_templates
      expect(resource.metadata_from_templates['template_property']).to eq 'this is a value'

      # Test default_rdf_classes
      expect(resource.default_rdf_classes).to match_array(["schema:CreativeWork", "schema:WebPage", 'schema:IndividualProduct'])
      expect(child_file.default_rdf_classes).to match_array(["schema:DigitalDocument", "schema:WebPage", 'schema:IndividualProduct'])

      # Test default_rdf_properties
      expect(resource.default_rdf_properties.dig('iris', 'rdf_properties', 'schema:url')).to eq 'http://purl.org/someuri'
      expect(child_file.default_rdf_properties.dig('iris', 'rdf_properties', 'schema:fileFormat')).to eq 'application/pdf'

      # Test load_metadata
      # This resource uses default source merging rules
      expect(child_file.load_metadata.dig('iris', 'rdf_properties', 'schema:description')).to eq 'This is some PDF file.' # From parent
      expect(child_file.load_metadata['file_property']).to eq 'this is a value' # From file
      expect(child_file.load_metadata['template_property']).to eq 'this is a value' # From template
      expect(child_file.load_metadata.dig('iris', 'rdf_properties', 'schema:url')).to eq 'http://localhost:4567/collections/test_collection/item1/some_pdf.pdf' # From default_rdf_properties

      # This resource merges all sources
      expect(resource.load_metadata.dig('iris', 'rdf_properties', 'schema:author').first['_label']).to eq 'Welker, Joshua S.' # From file
      expect(resource.load_metadata.dig('iris', 'rdf_properties', 'schema:author').last).to eq 'this is an author from a metadata file' # From file
      expect(resource.load_metadata.dig('iris', 'rdf_properties', 'schema:name').last).to eq 'this is a name from a template file' # From template
      expect(resource.load_metadata.dig('iris', 'rdf_properties', 'schema:url')).to eq 'http://purl.org/someuri' # From default_rdf_properties
      expect(resource.load_metadata.dig('iris', 'rdf_properties', 'schema:sku').first).to eq 'PZ7.F598295' # From self
    end


    it 'handles RDF vocabularies and formats' do
      # Test rdf_classes
      expect(resource.rdf_classes).to match_array(['schema:Article', 'schema:IndividualProduct'])
      expect(child_file.rdf_classes).to match_array(["schema:DigitalDocument", "schema:WebPage", 'schema:IndividualProduct'])

      # Test rdf_class_uris
      expect(resource.rdf_class_uris).to match_array(["http://schema.org/Article", "http://schema.org/IndividualProduct"])
      expect(child_file.rdf_class_uris).to match_array(["http://schema.org/DigitalDocument", "http://schema.org/WebPage", "http://schema.org/IndividualProduct"])

      # Test is_vocabulary?
      expect(resource.is_vocabulary?('schema')).to be true
      expect(resource.is_vocabulary?('dc')).to be false

      # Test rdf_properties
      expect(resource.rdf_properties['schema:description']).to eq 'This is a test item with many different types of files.'

      # Test to_vocabulary
      expect(resource.to_vocabulary('dc')['dc:language']).to eq 'en_US'

      # Test rdfa_prefix_string
      expect(resource.rdfa_prefix_string).to eq 'rdf: http://www.w3.org/1999/02/22-rdf-syntax-ns# rdfs: http://www.w3.org/2000/01/rdf-schema# schema: http://schema.org/ dc: http://purl.org/dc/terms/ bf: http://id.loc.gov/ontologies/bibframe/ bflc: http://id.loc.gov/ontologies/bflc/ foaf: http://xmlns.com/foaf/0.1/ marc: http://www.loc.gov/MARC21/slim# local: http://localhost:4567/ontology/'

      # Test to_rdfa_html
      expect(resource.to_rdfa_html).to include('<span property="schema:hasPart" resource="http://purl.org/someuri#some_excel_sheets.xlsx" >')

      # Test to_jsonld
      expect(JSON.parse(resource.to_jsonld).length).to eq 23

      # Test to_jsonld_graph
      expect(JSON.parse(resource.to_jsonld_graph)['@graph'].length).to eq 12

      # Test jsonld_context
      expect(Middleman::Sitemap::Resource.jsonld_context(app)['_id']).to eq '@id'

      # Test to_marc_in_json
      expect(resource.to_marc_in_json['fields'].length).to eq 12

      # Test convert_property_to_vocabulary
      expect(Middleman::Sitemap::Resource.convert_property_to_vocabulary('schema:name', 'dc', app)).to eq 'dc:title'

      # Test recursive_convert_to_vocabulary
      expect(Middleman::Sitemap::Resource.recursive_convert_to_vocabulary(resource.rdf_properties['schema:caption'], 'dc', app).dig('dc:contributor', 'dc:subject', 0)).to eq 'horses'

      # Test recursive_unpack_structure_to_rdfa
      expect(Middleman::Sitemap::Resource.recursive_unpack_structure_to_rdfa('schema:caption', resource.rdf_properties['schema:caption'])).to include('<span property="schema:keywords"> horses </span>')

    end


  end
end
