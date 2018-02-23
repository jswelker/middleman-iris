module Middleman
  module Iris
    module ResourceHelperExtensions


        def self.included(base)
          base.extend(Middleman::Iris::ResourceHelperExtensions::SingletonMethods)
        end


        def iris_value(keys)
          value = self.data&.dig('iris', *keys)
          if self.static_file? || self.page?
            value ||= self.data&.dig(*keys)
          end
          return value
        end


        def iris_option(option)
          return @app.extensions[:iris].options[option]
        end


        def iris_resource?
          return !self.ignored? && !self.in_metadata_dir? && (self.in_collections_dir? || self.page?)
        end


        def site_root?
          return self.path.start_with?('index.') && self.dirname.match(/\/#{@app.config[:source]}$/)
        end


        def in_collections_dir?
          self.source_file.start_with?( "#{@app.root}/#{@app.config[:source]}/#{iris_option(:collections_dir)}" )
        end


        def same_directory?(resource)
          self.dirname == resource.dirname
        end


        def files_in_same_directory
          @app.sitemap.resources.select{|r| r.same_directory?(self) && r.page_id != self.page_id}
        end


        def children_in_same_directory(type=nil)
          return self.files_in_same_directory.select do |f|
            match = f.parent == self
            if type == :collection
              match = match && f.collection?
            elsif type == :item
              match = match && f.item?
            elsif type == :page
              match = match && f.page?
            elsif type == :static_file
              match = match && f.static_file?
            end
            match
          end
        end


        def descendant_of?(potential_parent_resource)
          current_resource = self
          is_descendant = current_resource.parent&.page_id == potential_parent_resource.page_id
          has_parent = current_resource.parent.present?
          while has_parent && !is_descendant
            current_resource = current_resource.parent
            is_descendant = true if current_resource.parent&.page_id == potential_parent_resource.page_id
            has_parent = current_resource.parent.present?
          end
          return is_descendant
        end


        def collection
          if self.collection?
            return self
          elsif self.parent.blank?
            return nil
          end
          resource = self.parent
          collection = nil
          while collection.blank? && resource.present?
            collection = resource if resource.collection?
            resource = resource&.parent
          end
          return collection
        end


        def in_metadata_dir?
          return !!self.dirname.match(/\.metadata/)
        end


        def resource_file_size
          return self.class.file_size(self.source_file)
        end


        def first_timestamp
          if file_history.present?
            file_history.sort.first&.dig(1, 'timestamp')
          end
        end


        def last_timestamp
          if file_history.present?
            file_history.sort.last&.dig(1, 'timestamp')
          end
        end


        def last_checksum
          if file_history.present?
            file_history.sort.last&.dig(1, 'checksum')
          end
        end


        def current_checksum
          Digest::SHA256.file(self.source_file).hexdigest
        end


        def filename
          File.basename(self.source_file)
        end


        def dirname
          File.dirname(self.source_file)
        end


        def dirname_last
          self.dirname.split('/').last
        end


        def best_title
          if self.item? || self.collection? || self.site_root?
            return self.rdf_properties['schema:name'] || self.data.title || self.dirname_last
          elsif self.page?
            return self.rdf_properties['schema:name'] || self.data.title || self.parent&.data&.dig('iris', 'files', self.filename, 'rdf_properties', 'schema:name') || self.filename
          else
            return self.parent&.data&.dig('iris', 'children', self.filename, 'rdf_properties', 'schema:name') || self.filename
          end
        end


        def best_description
          if self.directory_index?
            return self.rdf_properties['schema:description'] || self.data.dig('iris', 'description') || nil
          elsif self.page?
            return self.rdf_properties['schema:description'] || self.data.dig('iris', 'description') || self.parent&.data&.dig('iris', 'files', self.filename, 'rdf_properties', 'schema:description') || nil
          else
            return self.parent&.data&.dig('iris', 'children', self.filename, 'rdf_properties', 'schema:description') || nil
          end
        end


        def best_creator
          return nil
        end


        def collection?
          return self.data.dig('iris', 'collection') || false
        end


        def item?
          return self.directory_index? && !self.collection?
        end


        def page?
          self.ext.include?('.htm') && !self.directory_index?
        end


        def static_file?
          !page?
        end


        def img?
          return %w(.png .jpg .jpeg .tif .tiff .gif).include?(self.ext)
        end


        def pdf?
          return %w(.pdf).include?(self.ext)
        end


        def spreadsheet?
          return %w(.xls .xlsx .csv .ods).include?(self.ext)
        end


        def word_doc?
          return %w(.doc .docx .odt).include?(self.ext)
        end


        def powerpoint?
          return %w(.ppt .pptx .odp).include?(self.ext)
        end


        def textfile?
          return %w(.txt .rtf).include?(self.ext)
        end


        def video?
          # TODO
        end


        def audio?
          # TODO
        end


        def resource_type
          return 'collection' if self.collection?
          return 'file' if self.static_file?
          return 'item' if self.item?
          return 'page' if self.page?
        end


        def position
          if static_file?
            return self.parent.data.dig('iris', 'files', self.filename, 'position')
          else
            return self.data.dig('iris', 'position')
          end
        end


        def permalink
          if @app.server?
          "http://localhost:#{@app.config.port}#{self.url}"
          else
            self.data.dig('iris', 'permalink') || iris_option(:root_url) + self.url
          end
        end


        def uri
          if self.item? || self.collection? || self.site_root?
            return self.permalink
          elsif self.page? && !self.in_collections_dir?
            return self.permalink
          else
            return (self.parent&.permalink || '').gsub(/\/$/,'') + '#' + self.uri_slug
          end
        end


        def uri_slug
          unless self.item? || self.collection?
            return self.best_title.underscore.squeeze(' ').gsub(' ','_')
          end
        end


        def icon
          if self.img?
            return 'far fa-image'
          elsif self.pdf?
            return 'far fa-file-pdf'
          elsif self.spreadsheet?
            return 'fas fa-table'
          elsif self.word_doc?
            return 'far fa-file-word'
          elsif self.powerpoint?
            return 'far fa-file-powerpoint'
          elsif self.textfile?
            return 'far fa-file-alt'
          elsif self.collection? || self.item?
            return 'fas fa-folder'
          else
            return 'far fa-file'
          end
        end


        def breadcrumb_resources
          crumbs = []
          crumbs << self

          page = self.parent
          while(page)
            crumbs << page
            page = page.parent
          end
          crumbs << @app.sitemap.resources.select{|r| r.path == 'index.html' && r.page_id != self.page_id}.first

          return crumbs.compact.reverse
        end

      module SingletonMethods

        def iris_resources(app)
          app.sitemap.resources.select{|r| r.iris_resource?}
        end


        def sort_resources(resources)
          return resources.sort do |a, b|
            a.position <=> b.position || a.best_title <=> b.best_title || 0
          end
        end


        def collections(sort=true)
          collections = sitemap.resources.select{|r| r.collection?}
          collections = self.sort_resources(collections) if sort
          return collections
        end


        def specific_resources(app, paths = [])
          collections = []
          paths.each do |p|
            collection = app.sitemap.resources.select{|r| r.path == p}.first
            collections << collection if collection.present?
          end
          return collections
        end


        def root_collections(sort=true)
          collections(sort).select{|r| r.parent.blank?}
        end


        def recently_added(parent_collection, limit)

        end


        def featured_items(parent_collection)
          if parent_collection.present?
            return parent_collection.children.select{|r| r.data&.dig('iris', 'featured')}
          else
            return sitemap.resources.select{|r| r.data&.dig('iris', 'featured')}
          end
        end


        def file_size(filename)
          size = File.size(filename)
          if size < 1024
            return "#{size} B"
          elsif size < (1024 * 1024)
            return "#{(size/1024.0).round(2)} KB"
          elsif size < (1024 * 1024 * 1024)
            return "#{(size/(1024*1024)).round(2)} MB"
          else
            return "#{(size/(1024*1024*1024)).round(2)} GB"
          end
        end


      end # END MODULE SingletonMethods
    end # END MODULE ResourceHelperExtensions
  end # END MODULE Iris
end
