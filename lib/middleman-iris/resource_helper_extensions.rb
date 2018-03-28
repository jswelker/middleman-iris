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


        def iris_resource?
          return !self.ignored? && !self.in_metadata_dir? && (self.in_collections_dir? || self.page?)
        end


        def site_root?
          return self.page_id == self.class.site_root(@app)&.page_id
        end


        def in_collections_dir?
          self.source_file.start_with?( "#{@app.root}/#{@app.config[:source]}/#{@app.extensions[:iris].options[:collections_dir]}" )
        end


        def same_directory?(resource)
          self.dirname == resource.dirname
        end


        def files_in_same_directory
          @app.sitemap.resources.select{|r| r.same_directory?(self) && r.page_id != self.page_id && !r.ignored?}
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


        # A faster method for finding the parent resource without traversing the whole sitemap
        def fast_parent
          check_path = self.dirname.gsub(/^.*?#{@app.config[:source]}\/?/, '') + "/#{@app.config[:index_file]}"
          if !self.directory_index?
            parent = @app.sitemap.find_resource_by_path(check_path)
            return parent if parent.present?
          end

          parent = nil
          while parent.blank? && check_path.length > 0 && check_path != @app.config[:index_file]
            check_path = (check_path.gsub(/[a-zA-Z0-9\-_\.]{1,}?\/?$/,'').gsub(/[a-zA-Z0-9\-_\.]*?\/?$/,'') + '/').gsub('//', '/') + "#{@app.config[:index_file]}"
            next if check_path == self.path || check_path == @app.config[:index_file]
            parent = @app.sitemap.find_resource_by_path(check_path)
          end
          return parent
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


        def best_field(field_name)
          field_content = nil
          @app.extensions[:iris].metadata_rankings[field_name]&.each do |ranking_name|
            if self.rdf_properties[ranking_name]
              field_content = self.rdf_properties[ranking_name]
              break
            end
          end
          field_content ||= self.data[field_name] || self.iris_value(field_name)
          if field_content.instance_of?(Array) || field_content.instance_of?(Hashie::Array)
            field_content = field_content.first
          end
          if (field_content.instance_of?(Hash) || field_content.instance_of?(Middleman::Util::EnhancedHash)) && field_content.has_key?('_label')
            field_content = field_content['_label']
          end
          return field_content
        end


        def best_title
          return self.best_field('title') || self.filename
        end


        def best_description
          return self.best_field('description')
        end


        def best_creator
          return self.best_field('creator')
        end


        def collection?
          return (self.data.dig('iris', 'collection') || false) && !self.in_metadata_dir? && self.in_collections_dir?
        end


        def item?
          return self.directory_index? && !self.collection? && !self.in_metadata_dir? && self.in_collections_dir?
        end


        def page?
          self.ext.include?('.htm') && !self.directory_index? && !self.in_metadata_dir? && self.in_collections_dir?
        end


        def static_file?
          !self.collection? && !self.item? && !self.page? && !self.in_metadata_dir? && self.in_collections_dir?
        end


        def img?
          return %w(.png .jpg .jpeg .tif .tiff .gif).include?(self.ext) && !self.in_metadata_dir? && self.in_collections_dir?
        end


        def pdf?
          return %w(.pdf).include?(self.ext) && !self.in_metadata_dir? && self.in_collections_dir?
        end


        def spreadsheet?
          return %w(.xls .xlsx .csv .ods).include?(self.ext) && !self.in_metadata_dir? && self.in_collections_dir?
        end


        def word_doc?
          return %w(.doc .docx .odt).include?(self.ext) && !self.in_metadata_dir? && self.in_collections_dir?
        end


        def powerpoint?
          return %w(.ppt .pptx .odp).include?(self.ext) && !self.in_metadata_dir? && self.in_collections_dir?
        end


        def textfile?
          return %w(.txt .rtf).include?(self.ext) && !self.in_metadata_dir? && self.in_collections_dir?
        end


        def video?
          return %w(.mp4 .m4v .mov .avi .flv .mpg .wmv).include?(self.ext) && !self.in_metadata_dir? && self.in_collections_dir?
        end


        def audio?
          return %w(.mp3 .aac .ogg .m4a .wma .flac .wav).include?(self.ext) && !self.in_metadata_dir? && self.in_collections_dir?
        end


        def resource_type
          return 'collection' if self.collection?
          return 'file' if self.static_file?
          return 'item' if self.item?
          return 'page' if self.page?
        end


        def featured?
          return self.iris_value(:featured) == true
        end


        def position
          return self.iris_value(:position)
        end


        def permalink
          if self.data.dig('iris', 'rdf_properties', 'schema:url') || self.metadata_from_parent.dig('iris', 'rdf_properties', 'schema:url')
            link = self.data.dig('iris', 'rdf_properties', 'schema:url') || self.metadata_from_parent.dig('iris', 'rdf_properties', 'schema:url')
          elsif self.data.dig('iris', 'permalink') || self.metadata_from_parent.dig('iris', 'permalink')
            link = self.data.dig('iris', 'permalink') || self.metadata_from_parent.dig('iris', 'permalink')
          elsif @app.server?
            link = "http://localhost:#{@app.config.port}#{self.url}"
          else
            link = @app.extensions[:iris].options[:root_url] + self.url
          end

          if link.instance_of?(Array) || link.instance_of?(Hashie::Array)
            return link.first
          else
            return link
          end
        end


        def uri
          if self.item? || self.collection? || self.site_root? || (self.page? && !self.in_collections_dir?)
            return self.permalink
          else
            return (self.fast_parent&.permalink || '').gsub(/\/$/,'') + '#' + self.uri_slug.to_s
          end
        end


        def uri_slug
          unless self.item? || self.collection?
            return self.best_title&.underscore&.squeeze(' ')&.gsub(' ','_')
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
          app.sitemap.resources.select{|r| r.iris_resource? && !r.ignored?}
        end


        def site_root(app)
          app.sitemap.find_resource_by_path('index.html')
        end


        def sort_resources(resources)
          return resources.sort do |a, b|
            if a.position.present? || b.position.present? && ((a.position || 1000000) <=> (b.position || 1000000)) != 0
              (a.position || 1000000) <=> (b.position || 1000000)
            else
              (a.best_title <=> b.best_title) || 0
           end
          end
        end


        def collections(app, sort=true)
          collections = app.sitemap.resources.select{|r| r.collection?}
          collections = self.sort_resources(collections) if sort
          return collections
        end


        def specific_resources(app, paths = [])
          resources = []
          paths.each do |p|
            resource = app.sitemap.find_resource_by_path(p)
            resource ||= app.sitemap.resources.select{|r| r.page_id == p}.first
            resources << resource if resource.present?
          end
          return resources
        end


        def root_collections(app, sort=true)
          collections(app, sort).select{|r| r.parent.blank?}
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
