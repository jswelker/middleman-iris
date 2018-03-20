module Middleman
  module Iris
    module ResourceValidatorExtensions

      def self.included(base)
        base.extend(Middleman::Iris::ResourceValidatorExtensions::SingletonMethods)
      end


      def uris
        uris = []
        rdf_props = self.rdf_properties
        rdf_props.extend(Hashie::Extensions::DeepLocate)
        rdf_props.deep_locate -> (k, v, obj) do
          next if %w(Array Hashie::Array Hash Middleman::Util::EnhancedHash).include?(v.class.to_s)
          uris << v if k == '_id' || k == '@id'
          uris << v if v.instance_of?(String) && (v.start_with?('http://') || v.start_with?('https://'))
        end
        return uris
      end


      def http_uris
        return self.uris.select{|uri| uri.start_with?('http://') || uri.start_with?('https://')}
      end


      def has_property?(property)
        return self.rdf_properties.has_key?(property)
      end


      def validate_uris
        errors = {}
        self.http_uris.each do |uri|
          next if uri.match(/https?:\/\/localhost/)
          puts "- Validating #{uri}..."
          response = HTTParty.get(uri)
          if !response.ok?
            errors[uri] = response.code
          end
        end
        return errors
      end


      def resources_with_duplicate_uris
        duplicates = []
        self.class.iris_resources(@app).select{|r| r.uri == self.uri && r.page_id != self.page_id}.each do |resource|
          duplicates << resource
        end
        return duplicates.uniq
      end


      module SingletonMethods

        def make_reports_dir(app)
          dir = "#{app.root}/#{app.extensions[:iris].options[:reports_directory]}"
          FileUtils.mkdir(dir) if !Dir.exist?(dir)
        end


        def validate_missing_properties(app, properties, directory=nil, static_files=false, to_file=true)
          resources_missing_properties = {}
          resources = iris_resources(app)
          if directory
            resources.select!{|r| r.source_file.start_with?(directory)}
          end
          if !static_files
            resources.select!{|r| !r.static_file?}
          end
          resources.each do |r|
            properties.each do |p|
              resources_missing_properties[r.page_id] ||= []
              resources_missing_properties[r.page_id] << p if !r.has_property?(p)
            end
          end

          if to_file
            make_reports_dir(app)
            CSV.open("#{app.root}/#{app.extensions[:iris].options[:reports_directory]}/missing_properties_#{Time.now.strftime('%Y-%m-%d_%h_%i_%s')}.csv", 'wb') do |csv|
              resources_missing_properties.each do |page_id, missing_properties|
                missing_properties.each do |property|
                  csv << [page_id, property]
                end
              end
            end
          end

          return resources_missing_properties
        end


        def validate_duplicate_uris(app, directory=nil, to_file=true)
          duplicates = {}
          resources = iris_resources(app)
          if directory
            resources.select!{|r| r.source_file.start_with?(directory)}
          end
          resources.each do |r|
            duplicates[r.page_id] = r.resources_with_duplicate_uris.map{|r| r.page_id}
          end

          if to_file
            make_reports_dir(app)
            CSV.open("#{app.root}/#{app.extensions[:iris].options[:reports_directory]}/duplicate_uris_#{Time.now.strftime('%Y-%m-%d_%h_%i_%s')}.csv", 'wb') do |csv|
              duplicates.each do |page_id, resources|
                resources.each do |dupe|
                  csv << [page_id, dupe]
                end
              end
            end
          end

          return duplicates
        end


        def validate_http_error_uris(app, directory=nil, to_file=true)
          errors = {}
          resources = iris_resources(app)
          if directory
            resources.select!{|r| r.source_file.start_with?(directory)}
          end
          uris = {}
          resources.each do |r|
            r.http_uris.each do |uri|
              uris[uri] ||= {
                resources: [],
                code: nil
              }
              uris[uri][:resources] << r.page_id
            end
          end

          # Don't bother checking URIs ending with a hash anchor if the base URI is already being checked.
          # Also don't bother checking URIs on localhost
          uris.delete_if do |uri, uri_hash|
            (uri.match(/#.*?$/) && uris.has_key?(uri.gsub(/#.*?$/, ''))) || uri.match(/https?:\/\/localhost/)
          end

          uris.each do |uri, uri_hash|
            puts "- Validating #{uri}..."
            response = HTTParty.get(uri)
            uris[uri][:code] = response.code
          end

          if to_file
            make_reports_dir(app)
            CSV.open("#{app.root}/#{app.extensions[:iris].options[:reports_directory]}/http_error_uris_#{Time.now.strftime('%Y-%m-%d_%h_%i_%s')}.csv", 'wb') do |csv|
              uris.each do |uri, uri_hash|
                csv << [uri, uri_hash[:code], uri_hash[:resources].join(', ')]
              end
            end
          end

          return uris
        end

      end # END MODULE SingletoneMethods
    end # END MODULE ResourceValidatorExtensions
  end # END MODULE Iris
end
