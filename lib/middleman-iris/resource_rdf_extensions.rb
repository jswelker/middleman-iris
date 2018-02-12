module Middleman
  module Iris
    module ResourceRdfExtensions


      attr_accessor :page_data


      def self.included(base)
        base.extend(Middleman::Iris::ResourceRdfExtensions::SingletonMethods)
      end


      def load_metadata
        front_matter = self.data
        complete_metadata = self.default_schema_properties
          .deep_merge(metadata_from_templates)
          .deep_merge(metadata_from_parent)
          .deep_merge(metadata_from_file)
          .deep_merge(front_matter)
        complete_metadata ||= Middleman::Util.recursively_enhance({})

        self.page_data = complete_metadata
        return complete_metadata
      end


      def metadata_from_parent
        return self.parent&.iris_value(['children', filename]) || Middleman::Util.recursively_enhance({})
      end


      def metadata_from_file
        hash = {}
        if File.exist?("#{metadata_directory_path}/#{filename}.yaml")
          hash = YAML.load_file("#{metadata_directory_path}/#{filename}.yaml")
        elsif File.exist?("#{metadata_directory_path}/#{filename}.yaml")
          hash = YAML.load_file("#{metadata_directory_path}/#{filename}.yml")
        elsif File.exist?("#{metadata_directory_path}/#{filename}.json")
          hash = YAML.load_file("#{metadata_directory_path}/#{filename}.json")
        end
        return Middleman::Util.recursively_enhance( hash )
      end


      def metadata_from_templates
        templates = self.iris_value('templates') || []
        metadata = Middleman::Util.recursively_enhance({})
        templates.each do |template|
          template_data = @app.data.to_h.dig(*template.split('/'))
          metadata.deep_merge!(template_data) unless template_data.blank?
        end
        metadata
      end


      def rdf_classes
        return self.iris_value('rdf_classes') || self.default_rdf_classes
      end


      def default_rdf_classes
        if self.pdf?
          return ["schema:DigitalDocument", "schema:WebPage", 'schema:IndividualProduct']
        elsif self.word_doc? || self.textfile?
          return ["schema:TextDigitalDocument", "schema:WebPage", 'schema:IndividualProduct']
        elsif self.spreadsheet?
          return ["schema:SpreadsheetDigitalDocument", "schema:WebPage", 'schema:IndividualProduct']
        elsif self.powerpoint?
          return ["schema:PresentationDigitalDocument", "schema:WebPage", 'schema:IndividualProduct']
        elsif self.img?
          return ["schema:ImageObject", "schema:WebPage", 'schema:IndividualProduct']
        elsif self.video?
          return ["schema:VideoObject", "schema:WebPage", 'schema:IndividualProduct']
        elsif self.audio?
          return ["schema:AudioObject", "schema:WebPage", 'schema:IndividualProduct']
        elsif self.collection?
          return ["schema:CollectionPage", "schema:WebPage", 'schema:IndividualProduct']
        elsif self.item?
          return ["schema:CreativeWork", "schema:WebPage", 'schema:IndividualProduct']
        elsif self.page?
          return ["schema:WebPage"]
        else
          return ["schema:WebPage"]
        end
      end


      def rdf_class_uris
        return self.rdf_classes.map{|c| self.vocabularies[c.split(':').first] + c.split(':').last}
      end


      def is_vocabulary?(vocabulary)
        is_vocab = false
        rdf_classes.each do |c|
          is_vocab = true if c.start_with?(vocabulary) || c == self.vocabularies[vocabulary]
        end
        return is_vocab
      end


      def rdf_properties
        return self.iris_value('rdf_properties') || {}
      end


      def default_rdf_properties
        properties = {}
        if self.is_vocabulary?('schema')
          properties = default_schema_properties
        elsif self.is_vocabulary?('rdf')
          properties = default_bibframe_properties
        end
        return properties
      end


      def default_schema_properties

        properties = {
          'schema:name' => self.best_title,
          'schema:description' => self.best_description,
          'schema:identifier' => self.uri,
          'schema:dateModified' => self.last_timestamp,
          'schema:datePublished' => self.first_timestamp,
          'schema:provider' => @app.config[:iris][:organization_name],
          'schema:url' => self.permalink,
          'schema:inLanguage' => @app.config[:iris][:default_language_code],
          'schema:disambiguatingDescription' => "#{self.last_checksum} (SHA256)"
        }

        if self.collection? || self.item?
          properties['schema:hasPart'] = self.children.map{|c| {
            '_label' => c.best_title,
            '_id' => c.uri
          }}
        elsif self.static_file?
          properties['schema:contentUrl'] = self.filename
          properties['schema:contentSize'] = self.file_size
          properties['schema:fileFormat'] = MIME::Types.type_for(self.filename).first.to_s
          properties['schema:isPartOf'] = self.parent&.permalink
          properties['schema:thumbnailUrl'] = self.thumbnail_url
        elsif self.page?
          properties['schema:mainEntity'] = self.parent&.permalink
          properties['schema:isPartOf'] = self.parent&.permalink
        end

        return Middleman::Util.recursively_enhance({iris: {rdf_properties: properties}})
      end


      def default_bibframe_properties
        # TODO
        {}
      end


      def vocabularies
        return {
          'rdf' => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
          'rdfs' => 'http://www.w3.org/2000/01/rdf-schema#',
          'schema' => 'http://schema.org/',
          'dc' => 'http://purl.org/dc/terms/',
          'bf' => 'http://id.loc.gov/ontologies/bibframe/',
          'bflc' => 'http://id.loc.gov/ontologies/bflc/',
          'foaf' => 'http://xmlns.com/foaf/0.1/',
          'local' => @app.config.to_h.dig(:iris, :root_url)
        }
      end


      def rdfa_prefix_string
        return self.vocabularies.map{|k, v| "#{k}: #{v}"}.join(' ')
      end


      def to_rdfa_html(element1='div', element2='div', element3='span', element1_class='', padding_element=false)
        html = "<#{element1} class=\"#{element1_class}\">"
        html += "<#{element2}><#{element3}></#{element3}><#{element3}></#{element3}></#{element2}>" if padding_element
        self.rdf_properties.each do |k, v|
          html += self.class.recursive_unpack_structure_to_rdfa(k, v, element1, element2, element3)
        end
        html += "</#{element1}>"
        return html.html_safe
      end


      def jsonld_context
        return {
          '_id' => '@id',
          '_type' => '@type',
          '_value' => '@value',
          '_label' => 'http://www.w3.org/2000/01/rdf-schema#label',
          '@vocab' => @app.config.to_h.dig(:iris, :root_url)
        }.merge(self.vocabularies)
      end


      def to_jsonld
        return {
          '@context' => self.jsonld_context,
          '@id' => self.uri,
          '@type' => self.rdf_class_uris,
        }.deep_merge(self.rdf_properties).to_json
      end


      def to_jsonld_graph
        rdf_objects = [self] + self.children_in_same_directory
        jsonld = {
          '@context' => self.jsonld_context,
          '@graph' => rdf_objects.map{|o| {'@id' => o.uri, '@type' => o.rdf_class_uris }.deep_merge(o.rdf_properties) }
        }
        return jsonld.to_json
      end


      def to_rdf_graph(bundle)
        if bundle
          graph = RDF::Graph.new << JSON::LD::API.toRdf(JSON.parse(self.to_jsonld))
        else
          graph = RDF::Graph.new << JSON::LD::API.toRdf(JSON.parse(self.to_jsonld_bundle))
        end
      end


      def to_turtle(bundle)
        return self.to_rdf_graph(bundle).to_ttl
      end


      def to_ntriples(bundle)
        return self.to_rdf_graph(bundle).to_ntriples
      end


      module SingletonMethods


        def recursive_unpack_structure_to_rdfa(k, v, element1='div', element2='div', element3='span')
          html = ''

          if v.instance_of?(Array) || v.instance_of?(Hashie::Array)
            v.each do |array_v|
              html += recursive_unpack_structure_to_rdfa(k, array_v, element1, element2, element3)
            end

          elsif (v.instance_of?(Hash) || v.instance_of?(Middleman::Util::EnhancedHash)) && \
            (v.keys.length == 2 && v.has_key?('_id') || v.keys.length == 2 && v.has_key?('_id') && v.has_key?('_type') )

            html += "<#{element2}>
              <#{element3}>#{k}</#{element3}>
              <#{element3} property=\"#{k}\" resource=\"#{v['_id']}\" #{if v.has_key?('_type') then 'typeof="'+ v['_type'] +'"' end}>
                <a href=\"#{v['_id']}\" property=\"#{v.select{|k1, v1| k1 != '_id' && k1 != '_type'}.keys.first}\">
                  #{v.select{|k1, v1| k1 != '_id' && k1 != '_type'}.values.first}
                </a>
              </#{element3}>
            </#{element2}>"

          elsif v.instance_of?(Hash) || v.instance_of?(Middleman::Util::EnhancedHash)
            html += "<#{element2}>"
            html += "<#{element3}>#{k}</#{element3}>"
            html +=  "<#{element3} property=\"#{k}\">"
            html += "<#{element1}>"
            v.each do |hash_k, hash_v|
              html += recursive_unpack_structure_to_rdfa(hash_k, hash_v, element1, element2, element3)
            end
            html += "</#{element1}>"
            html += "</#{element3}>"
            html += "</#{element2}>"

          elsif v.present?
            formatted_value = v
            if v.to_s.match(/^https?:/)
              formatted_value = "<a href=\"#{v}\">#{v}</a>"
            end

            html += "<#{element2}>
              <#{element3}>#{k}</#{element3}>
              <#{element3} property=\"#{k}\"> #{formatted_value} </#{element3}>
            </#{element2}>"
          end

          return html.html_safe
        end

      end # END MODULE SingletonMethods
    end # END MODULE ResourceMetadata
  end # END MODULE Iris
end
