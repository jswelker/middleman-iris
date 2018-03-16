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
          uris << v if v.start_with?('http://') || v.start_with?('https://')
        end
        return uris
      end


      def http_uris
        return self.uris.select{|uri| uri.start_with?('http://') || uri.start_with?('https://')}
      end


      def has_property?(property)
        return self.rdf_properties.has_key?(property)
      end


      def identifiers
        return [self.to_vocabulary('dc')['dc:identifier']].flatten
      end


      def validate_uris
        errors = {}
        self.http_uris.each do |uri|
          response = HTTParty.get(uri)
          if !response.ok?
            errors[uri] = response.code
          end
        end
        return errors
      end


      def check_duplicate_uris
        errors = {}
        self.identifiers.each do |id|
          self.class.iris_resources(@app).select{|r| r.identifiers.include?(id)}.each do |dupe|
            errors[dupe.page_id] ||= []
            errors[dupe.page_id] << id
          end
        end
        return errors
      end


      module SingletonMethods

      end # END MODULE SingletoneMethods
    end # END MODULE ResourceValidatorExtensions
  end # END MODULE Iris
end
