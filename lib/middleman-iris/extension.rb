require 'rdf'
require "rdf/rdfxml"
require "rdf/turtle"
require "json/ld"
require "mime-types"
require "rmagick"
require "pdf-reader"
require "roo"
require "nokogiri"
require "object_flatten"
require "httparty"
require 'pry'
require 'middleman-iris/resource_helper_extensions'
require 'middleman-iris/resource_processing_extensions'
require 'middleman-iris/resource_rdf_extensions'
require 'middleman-iris/resource_validator_extensions'

module Middleman
  module Iris
    class IrisExtension < Extension

      include Iris::ResourceHelperExtensions::SingletonMethods
      include Iris::ResourceProcessingExtensions::SingletonMethods
      include Iris::ResourceRdfExtensions::SingletonMethods
      include Iris::ResourceValidatorExtensions::SingletonMethods

      expose_to_template :sort_resources, :collections, :specific_resources, :root_collections, :recently_added, :featured_items,
      :recursive_unpack_structure_to_rdfa, :build_indexes

      option :collections_dir, 'collections', 'Name of the root directory where collections live.'
      option :filenames_to_ignore, %w(.keep), 'Names of files to ignore.'
      option :generate_thumbnails_on_build, true, 'Whether to generate thumbnails on command "middleman build"'
      option :generate_thumbnails_on_serve, false, 'Whether to generate thumbnails on command "middleman serve"'
      option :generate_history_on_build, true, 'Whether to generate file history on command "middleman build"'
      option :generate_history_on_serve, false, 'Whether to generate file history on command "middleman serve"'
      option :generate_text_on_build, true, 'Whether to generate index text on command "middleman build"'
      option :generate_text_on_serve, false, 'Whether to generate index text on command "middleman serve"'
      option :generate_indexes_on_build, true, 'Whether to generate search indexes on command "middleman build"'
      option :generate_indexes_on_serve, false, 'Whether to generate search indexes on command "middleman serve"'
      option :root_url, '', 'Root URL to apply to permalinks and URIs'
      option :search_page, 'pages/search', 'ID of search results page'
      option :organization_name, '', 'Name of the organization that owns this website'
      option :default_language_code, 'en_US', 'Default language code for documents on this website'
      option :libreoffice_dir, nil, 'Where to find the LibreOffice executable for converting office files to PDF'
      option :html_text_indexing_selector, nil, 'CSS selector for indexing text of HTML pages on this site'
      option :default_rdf_values, {}, 'Default RDF values to apply to all documents'
      option :index_default_properties, %w(schema:name schema:description schema:author schema:keywords schema:copyrightYear bf:title bf:contribution bf:subject), 'Default properties indexed for each resource.'
      option :index_default_file_text, '100%', 'Default amount of text indexed for each file. Either a percent of number of total characters'
      option :index_field_weights, {
        default: 10,
        text: 1,
        "schema:name" => 20,
      }, 'Index weights to assign to specific fields to influence search result ranking'
      option :index_for_files_like, [], 'Rules for indexing files whose name/ext/path match a regex.'
      # [{
      #   regex: /html/,
      #   properties: ['schema:name', 'schema:description'],
      #   file_text: 0
      # }]

      def initialize(app, options_hash={}, &block)
        super

        app.extensions.activate(:vcs_time)

        Middleman::Sitemap::Resource.include(Iris::ResourceHelperExtensions)
        Middleman::Sitemap::Resource.include(Iris::ResourceProcessingExtensions)
        Middleman::Sitemap::Resource.include(Iris::ResourceRdfExtensions)
        Middleman::Sitemap::Resource.include(Iris::ResourceValidatorExtensions)

        @app = app
        ext = self

        app.after_configuration do
          app.sitemap.register_resource_list_manipulator(:iris, ext)
        end

        app.ready do
          # Generate index
          if (app.build? && ext.options[:generate_indexes_on_build]) || (app.server? && ext.options[:generate_indexes_on_serve])
            puts 'Generating search indexes...'
            ext.build_indexes(app)
          end
          # Generate bib metadata formats

          # Generate RSS

          # Generate OAI
        end
      end


      def manipulate_resource_list(resources)
        return resources if @run_once
        @run_once ||= true

        resources.each do |r|
          next if r.instance_of?(Middleman::Sitemap::Extensions::RedirectResource)

          # Ignore if YAML front matter indicates so
          if r.parent&.iris_value('ignore_children') || r.data['ignored']
            r.ignore!
          end
          # Ignore if this filename is designated to ignore in iris options
          if (options[:filenames_to_ignore] || []).include?(File.basename(r.source_file))
            r.ignore!
          end
          # Ignore files in _metadata directories
          if r.dirname_last == '.metadata'
            r.ignore!
          end
        end

        # Generate file history metadata
        if (app.build? && options[:generate_history_on_build]) || (app.server? && options[:generate_history_on_serve])
          puts 'Generating file history and checksums...'
          resources.each do |r|
            next if r.ignored? || !r.in_collections_dir? || r.instance_of?(Middleman::Sitemap::Extensions::RedirectResource)
            r.add_file_history
          end
        end

        # Generate full text for indexing
        if (app.build? && options[:generate_text_on_build]) || (app.server? && options[:generate_text_on_serve])
          puts 'Generating file text for indexing...'
          resources.each do |r|
            next if r.ignored? || !r.in_collections_dir? || r.instance_of?(Middleman::Sitemap::Extensions::RedirectResource) || r.in_metadata_dir?
            r.rip_text_to_file
          end
        end

        # Generate thumbnails
        if (app.build? && options[:generate_thumbnails_on_build]) || (app.server? && options[:generate_thumbnails_on_serve])
          puts 'Generating thumbnails...'
          resources.each do |r|
            next if r.ignored? || !r.in_collections_dir? || r.instance_of?(Middleman::Sitemap::Extensions::RedirectResource) || r.in_metadata_dir?
            r.generate_thumbnail
          end
        end

        # Load metadata
        if resources.present?
          puts 'Loading metadata from defaults, templates, and parents...'
          resources.each do |r|
            next if r.ignored? || !r.in_collections_dir? || r.instance_of?(Middleman::Sitemap::Extensions::RedirectResource) || r.in_metadata_dir?
            r.load_metadata
          end
        end

        return resources
      end

    end
  end
end
