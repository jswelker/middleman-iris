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


        def in_collections_dir?
          self.source_file.start_with?( "#{@app.root}/#{@app.config[:source]}/#{@app.config[:iris][:collections_dir] || 'collections'}" )
        end


        def same_directory?(resource)
          self.dirname == resource.dirname
        end


        def files_in_same_directory
          @app.sitemap.resources.select{|r| same_directory?(self) && r.page_id != self.page_id}
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


        def file_size
          size = File.size(self.source_file)
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
          if self.item? || self.collection?
            return self.data.dig('iris', 'schema_properties', 'name') || self.data.title || self.dirname_last
          elsif self.page?
            return self.data.dig('iris', 'schema_properties', 'name') || self.data.title || self.parent.data.dig('iris', 'files', self.filename, 'schema_properties', 'name') || self.filename
          else
            return self.parent.data.dig('iris', 'files', self.filename, 'schema_properties', 'name') || self.filename
          end
        end


        def best_description
          if self.directory_index?
            return self.data.dig('iris', 'schema_properties', 'description') || self.data.dig('iris', 'description') || nil
          elsif self.page?
            return self.data.dig('iris', 'schema_properties', 'description') || self.data.dig('iris', 'description') || self.parent.data.dig('iris', 'files', self.filename, 'schema_properties', 'description') || nil
          else
            return self.parent.data.dig('iris', 'files', self.filename, 'schema_properties', 'description') || nil
          end
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
            self.data.dig('iris', 'permalink') || @app.config[:iris][:root_url] + self.url
          end
        end


        def uri
          if self.item? || self.collection?
            return self.permalink
          else
            return self.parent.permalink + '#' + self.uri_slug
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
          crumbs << @app.sitemap.resources.select{|r| r.path == 'index.html'}.first

          return crumbs.reverse
        end

      module SingletonMethods


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


        def specific_resources(paths = [])
          collections = []
          paths.each do |p|
            collection = sitemap.resources.select{|r| r.path == p}.first
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


      end # END MODULE SingletonMethods
    end # END MODULE ResourceHelperExtensions
  end # END MODULE Iris
end
