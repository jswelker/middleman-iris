require 'rdf/ntriples'
# require 'lib/iris/resource_helper_extensions'
# require 'lib/iris/resource_processing_extensions'
# require 'lib/iris/resource_rdf_extensions'
# require 'lib/iris/resource_validator_extensions'

module Middleman
  module Iris
    class IrisExtension < Extension

      # include Iris::ResourceHelperExtensions::SingletonMethods
      # include Iris::ResourceProcessingExtensions::SingletonMethods
      # include Iris::ResourceRdfExtensions::SingletonMethods
      # include Iris::ResourceValidatorExtensions::SingletonMethods
      # expose_to_template :sort_resources, :collections, :specific_resources, :root_collections, :recently_added, :featured_items,
      # :recursive_unpack_structure_to_rdfa
      #
      #
      # def initialize(app, options_hash={}, &block)
      #   Middleman::Sitemap::Resource.include(Iris::ResourceHelperExtensions)
      #   Middleman::Sitemap::Resource.include(Iris::ResourceProcessingExtensions)
      #   Middleman::Sitemap::Resource.include(Iris::ResourceRdfExtensions)
      #   Middleman::Sitemap::Resource.include(Iris::ResourceValidatorExtensions)
      #
      #
      #   @app = app
      #   app.sitemap.register_resource_list_manipulator(:iris, self)
      # end
      #
      #
      # def manipulate_resource_list(resources)
      #   resources.each do |r|
      #     next if r.instance_of?(Middleman::Sitemap::Extensions::RedirectResource)
      #
      #     # Ignore if YAML front matter indicates so
      #     if r.parent&.iris_value('ignore_children') || r.data['ignored']
      #       r.ignore!
      #     end
      #     # Ignore if this filename is designated to ignore in config.rb
      #     if (app.config.to_h.dig(:iris, :filenames_to_ignore) || []).include?(File.basename(r.source_file))
      #       r.ignore!
      #     end
      #     # Ignore files in _metadata directories
      #     if r.dirname_last == '_metadata'
      #       r.ignore!
      #     end
      #
      #     next if r.ignored? || !r.in_collections_dir?
      #
      #     # Generate file history metadata
      #     if (app.build? && app.config.to_h.dig(:iris, :generate_history_on_build)) || (app.server? && app.config.to_h.dig(:iris, :generate_history_on_serve))
      #       r.add_file_history
      #     end
      #
      #     # Generate full text for indexing
      #     if (app.build? && app.config.to_h.dig(:iris, :generate_text_on_build)) || (app.server? && app.config.to_h.dig(:iris, :generate_text_on_serve))
      #       r.rip_text_to_file
      #     end
      #
      #     # Generate thumbnails
      #     if (app.build? && app.config.to_h.dig(:iris, :generate_thumbnails_on_build)) || (app.server? && app.config.to_h.dig(:iris, :generate_thumbnails_on_serve))
      #       r.generate_thumbnail
      #     end
      #
      #     # Load metadata
      #     r.load_metadata
      #
      #   end
      #
      #   return resources
      # end
      #
      #
      # def before_build
      #   #TODO: NEED TO REGISTER THIS METHOD???
      #   # app.sitemap.resources.each do |r|
      #   # Generate index
      #   self.build_index();
      #
      #   # Generate bib metadata formats
      #
      #   # Generate RSS
      #
      #   # Generate OAI
      # end

    end
  end
end
