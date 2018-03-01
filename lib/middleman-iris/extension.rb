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
require 'rss'
require 'pry'
require 'middleman-iris/resource_helper_extensions'
require 'middleman-iris/resource_processing_extensions'
require 'middleman-iris/resource_rdf_extensions'
require 'middleman-iris/resource_validator_extensions'
require 'middleman-iris/cli/generate_history'
require 'middleman-iris/cli/generate_thumbnails'
require 'middleman-iris/cli/generate_text'
require 'middleman-iris/cli/generate_index'
require 'middleman-iris/cli/generate_rss'
require 'middleman-iris/cli/generate_oai'

module Middleman
  module Iris
    class IrisExtension < Extension

      include Iris::ResourceHelperExtensions::SingletonMethods
      include Iris::ResourceProcessingExtensions::SingletonMethods
      include Iris::ResourceRdfExtensions::SingletonMethods
      include Iris::ResourceValidatorExtensions::SingletonMethods

      attr_accessor :metadata_mappings

      expose_to_template :sort_resources, :collections, :specific_resources, :root_collections,
      :recursive_unpack_structure_to_rdfa

      option :generate_thumbnails_on_build, false, 'Whether to generate thumbnails on command "middleman build"'
      option :generate_thumbnails_on_serve, false, 'Whether to generate thumbnails on command "middleman serve"'
      option :generate_history_on_build, true, 'Whether to generate file history on command "middleman build"'
      option :generate_history_on_serve, false, 'Whether to generate file history on command "middleman serve"'
      option :generate_text_on_build, false, 'Whether to generate index text on command "middleman build"'
      option :generate_text_on_serve, false, 'Whether to generate index text on command "middleman serve"'
      option :generate_rss_on_build, true, 'Whether to generate rss feed on command "middleman build"'
      option :generate_rss_on_serve, false, 'Whether to generate rss feed on command "middleman serve"'
      option :generate_oai_on_build, true, 'Whether to generate OAI-PMH Static Repository file on command "middleman build"'
      option :generate_oai_on_serve, false, 'Whether to generate OAI-PMH Static Repository file on command "middleman serve"'
      option :generate_index_on_build, true, 'Whether to generate search index on command "middleman build"'
      option :generate_index_on_serve, false, 'Whether to generate search index on command "middleman serve"'
      option :root_url, '', 'Root URL to apply to permalinks and URIs'
      option :organization_name, '', 'Name of the organization that owns this website'
      option :site_name, '', 'Name of this website'
      option :admin_email, '', 'Email address(es)'
      option :default_language_code, 'en_US', 'Default language code for documents on this website'
      option :collections_dir, 'collections', 'Name of the root directory where collections live.'
      option :filenames_to_ignore, %w(.keep), 'Names of files to ignore.'
      option :libreoffice_dir, nil, 'Where to find the LibreOffice executable for converting office files to PDF'
      option :html_text_indexing_selector, nil, 'CSS selector for indexing text of HTML pages on this site'
      option :default_rdf_values, {}, 'Default RDF values to apply to all documents'
      option :oai_static_repository_gateway_url, '', 'URL of OAI-PMH Static Repository Gateway that provides access to this site\'s OAI-PMH Static Repository file'
      option :custom_metadata_mappings_file, nil, 'Path from root dir to custom file for metadata crosswalk mappings (YAML or JSON)'
      option :index_default_properties, %w(schema:name schema:description schema:author schema:keywords schema:copyrightYear bf:title bf:contribution bf:subject), 'Default properties indexed for each resource.'
      option :index_default_file_text, '100%', 'Default amount of text indexed for each file. Either a percent of number of total characters'
      option :index_field_weights, {
        default: 10,
        id: 1,
        bt: 30,
        bd: 20,
        bc: 50,
        sc: 0.01,
        co: 0.01,
        tx: 1,
        tn: 0.01,
        i: 0.01
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

        app.ready do
          ext.ignore_resources(app.sitemap.resources)
          ext.load_metadata_from_files(app.sitemap.resources)

          if ext.options[:custom_metadata_mappings_file].present?
            ext.metadata_mappings = YAML.load_file("#{root_path}/#{ext.options[:custom_metadata_mappings_file]}")
          else
            ext.metadata_mappings = YAML.load_file("#{Gem.datadir('middleman-iris')}/metadata_mappings.yaml")
          end

          if (app.build? && ext.options[:generate_history_on_build] && app.config[:iris_cli].blank?) || (app.server? && ext.options[:generate_history_on_serve])
            ext.generate_history(app.sitemap.resources)
          end

          if (app.build? && ext.options[:generate_text_on_build] && app.config[:iris_cli].blank?) || (app.server? && ext.options[:generate_text_on_serve])
            ext.generate_text(app.sitemap.resources)
          end

          if (app.build? && ext.options[:generate_thumbnails_on_build] && app.config[:iris_cli].blank?) || (app.server? && ext.options[:generate_thumbnails_on_serve])
            ext.generate_thumbnails(app.sitemap.resources)
          end

          if (app.build? && ext.options[:generate_index_on_build] && app.config[:iris_cli].blank?) || (app.server? && ext.options[:generate_index_on_serve])
            ext.generate_rss(app)
          end

          # Generate bib metadata formats

          # Generate RSS
          if (app.build? && ext.options[:generate_rss_on_build] && app.config[:iris_cli].blank?) || (app.server? && ext.options[:generate_rss_on_serve])
            ext.generate_index(app)
          end

          # Generate OAI
          if (app.build? && ext.options[:generate_oai_on_build] && app.config[:iris_cli].blank?) || (app.server? && ext.options[:generate_oai_on_serve])
            ext.generate_oai(app)
          end
        end
      end


    end
  end
end
