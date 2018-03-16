module Middleman
  module Iris
    module ResourceProcessingExtensions


      def self.included(base)
        base.extend(Middleman::Iris::ResourceProcessingExtensions::SingletonMethods)
      end


      def metadata_directory_path
        "#{self.dirname}/.metadata"
      end


      def create_metadata_directory
        if !Dir.exist?(File.dirname(file_history_path))
          Dir.mkdir(File.dirname(file_history_path))
        end
      end


      def file_history_path
        "#{metadata_directory_path}/#{self.filename}.history.yaml"
      end


      def file_history
        if File.exist?(file_history_path)
          return YAML.load_file(file_history_path) || {}
        else
          return {}
        end
      end


      def add_file_history
        if self.last_checksum != self.current_checksum && self.in_collections_dir? && !self.ignored? && !self.in_metadata_dir?
          history = self.file_history
          history[Time.now] = {
            'timestamp' => Time.now,
            'checksum' => self.current_checksum
          }
          create_metadata_directory
          File.open(file_history_path, 'w'){|f| f.write history.to_yaml}
          if File.exist?(self.thumbnail_path)
            FileUtils.rm(self.thumbnail_path)
          end
          if File.exist?(self.text_file_path)
            FileUtils.rm(self.text_file_path)
          end
        end
      end


      def text_file_path
        "#{self.dirname}/.metadata/#{self.filename}.txt"
      end


      def text
        if File.exist?(text_file_path)
          File.read(text_file_path).gsub(/\s/, ' ').squeeze("\r\n ")
        end
      end


      def index_text
        text_length = self.best_index_rules[:file_text]
        if text_length.to_s.include?('%')
          chars = (self.text&.length || 0 ) * (text_length.to_f / 100)
          return (self.text || "")[0..(chars.to_i)].strip
        else
          return (self.text || "")[0..(text_length.to_f)].strip
        end
      end


      def rip_text_to_file
        return nil if !self.in_collections_dir? || self.ignored?

        text = nil

        # First see if text file exists and if file checksum is the same
        create_metadata_directory
        return nil if File.exist?(text_file_path)

        # Otherwise, rip text and save it before returning
        if self.page?
          # Rip rendered HTML page content using Nokogiri
          doc = Nokogiri::HTML(self.render)
          text = doc.css(@app.extensions[:iris].options[:html_text_indexing_selector]).text
          File.open(text_file_path, 'w'){|f| f.write text}
        elsif self.pdf?
          # Rip PDF text using pdf-reader library
          reader = PDF::Reader.new(self.source_file)
          page_text = []
          reader.pages.each do |page|
            page_text << page.text
          end
          text = page_text.join("\n")
          File.open(text_file_path, 'w'){|f| f.write text}
        elsif self.word_doc? && Dir.exists?(@app.extensions[:iris].options[:libreoffice_dir].to_s)
          # Rip Office documents using LibreOffice CLI convert tool
          system("\"#{@app.extensions[:iris].options[:libreoffice_dir]}/soffice.exe\" --headless --convert-to txt \"#{self.source_file}\" --outdir \"#{metadata_directory_path}\"")
          system("mv \"#{text_file_path.gsub(self.ext, '')}\" \"#{text_file_path}\"")
        elsif self.spreadsheet? && Dir.exists?(@app.extensions[:iris].options[:libreoffice_dir].to_s)
          # Rip spreadsheets using the Roo library
          workbook = Roo::Spreadsheet.open(self.source_file)
          text = ''
          workbook.sheets.each do |sheet_name|
            text += workbook.sheet(sheet_name).to_csv
          end
          File.open(text_file_path, 'w'){|f| f.write text}
        elsif self.powerpoint? && Dir.exists?(@app.extensions[:iris].options[:libreoffice_dir].to_s)
          # Rip Powerpoint files to PDF using LibreOffice CLI and then from PDF to txt using pdf-reader library
          system("\"#{@app.extensions[:iris].options[:libreoffice_dir]}/soffice.exe\" --headless --convert-to pdf \"#{self.source_file}\" --outdir \"#{metadata_directory_path}\"")
          pdf_path = text_file_path.gsub(self.ext+'.txt', '.pdf')
          reader = PDF::Reader.new(pdf_path)
          page_text = []
          reader.pages.each do |page|
            page_text << page.text
          end
          text = page_text.join("\n")
          File.open(text_file_path, 'w'){|f| f.write text}
          File.delete(pdf_path)
        elsif self.textfile?
          # Copy plain text files
          FileUtils.cp(self.source_file, text_file_path)
        end

      end


      def thumbnail_path
        "#{@app.root}/#{@app.config[:source]}/#{@app.config[:images_dir]}/thumbnails/#{self.page_id}.png"
      end


      def thumbnail?
        File.exist?(self.thumbnail_path)
      end


      def thumbnail_url
        return unless self.thumbnail?

        if @app.server?
        "http://localhost:#{@app.config.port}#{@app.sitemap.resources.select{|r| r.source_file == self.thumbnail_path}.first&.url}"
        else
          self.data.dig('iris', 'permalink') || @app.extensions[:iris].options[:root_url] + @app.sitemap.resources.select{|r| r.source_file == self.thumbnail_path}.first&.url
        end
      end


      def child_thumbnail?
        self.children.select{|child| child.thumbnail?}.first.present?
      end


      def child_thumbnail_url
        self.children.select{|child| child.thumbnail?}.first&.thumbnail_url
      end


      def generate_thumbnail(force_regenerate=false)
        return if !self.in_collections_dir? || self.ignored?
        return if self.last_checksum == self.current_checksum && !force_regenerate && self.thumbnail?

        puts "Building thumbnail for #{self.page_id}}..."
        start_time = Time.now

        thumbnail = nil

        if self.img?
          original = Magick::Image.read(self.source_file).first
          thumbnail = original.resize_to_fit(200, 200)
          original.destroy!
        end

        if self.pdf?
          pdf = Magick::ImageList.new(self.source_file)
          first_page = pdf.first
          thumbnail = first_page.resize_to_fit(200, 200)
          first_page.destroy!
        end

        if (self.powerpoint? || self.word_doc? || self.spreadsheet?)  && Dir.exists?(@app.extensions[:iris].options[:libreoffice_dir].to_s)
          system("\"#{@app.extensions[:iris].options[:libreoffice_dir]}/soffice.exe\" --convert-to pdf --outdir \"#{self.dirname}\" \"#{self.source_file}\"")
          sleep(1)
          pdf_file = self.source_file.gsub(self.ext, '') + '.pdf'
          pdf = Magick::ImageList.new(pdf_file)
          first_page = pdf.first
          thumbnail = first_page.resize_to_fit(200, 200)
          first_page.destroy!
          File.delete(pdf_file)
        end

        if thumbnail
          # Add thumbnail to Middleman assets img dir
          new_dir = File.dirname(self.thumbnail_path)
          FileUtils.mkdir_p(new_dir)
          thumbnail.write(self.thumbnail_path)
          thumbnail.destroy!
        end
        puts "Finished in #{Time.now - start_time}"
      end


      def best_index_rules
        # Hard-coded default
        rules = {
          properties: %w(schema:name schema:description schema:author schema:keywords schema:copyrightYear bf:title bf:contribution bf:subject),
          file_text: '100%'
        }

        config = @app.config.to_h
        # App default
        rules[:properties] = @app.extensions[:iris].options[:index_default_properties] || rules[:properties]
        rules[:file_text] = @app.extensions[:iris].options[:index_default_file_text] || rules[:file_text]

        # File regex default
        rules[:properties] = @app.extensions[:iris].options[:index_for_files_like]&.select{|r| self.page_id.match(r[:regex])}&.last&.dig(:properties) || rules[:properties]
        rules[:file_text] = @app.extensions[:iris].options[:index_for_files_like]&.select{|r| self.page_id.match(r[:regex])}&.last&.dig(:file_text) || rules[:file_text]

        # Doc-specific
        rules[:properties] = self.iris_value(:indexing)&.dig(:properties) || rules[:properties]
        rules[:file_text] = self.iris_value(:indexing)&.dig(:file_text) || rules[:file_text]

        return rules
      end


      def index_scopes
        collections = @app.sitemap.resources.select{|r| r.site_root? || (r.collection? && self.descendant_of?(r)) }
        scopes = {}
        collections.each do |c|
          index_name = c.best_title
          index_name = @app.config[:site_name] if @app.config[:site_name].present? && c.site_root?
          scopes[c.page_id] = index_name
        end
        return scopes
      end


      module SingletonMethods


        def ignore_resources(resources)
          resources.each do |r|
            next if r.instance_of?(Middleman::Sitemap::Extensions::RedirectResource)

            # Ignore if YAML front matter indicates so
            r.ignore! if r.parent&.iris_value('ignore_children') || r.iris_value('ignored') || r.data['ignored']

            # Ignore if this filename is designated to ignore in iris options
            r.ignore! if (options[:filenames_to_ignore] || []).include?(File.basename(r.source_file))

            # Ignore directories indicated by options[:directories_to_skip]
            r.ignore! if (options[:directories_to_skip] || []).include?(r.dirname_last)

          end
        end


        def load_metadata_from_files(resources)
          puts 'Loading metadata from defaults, templates, and parents...'
          resources.each do |r|
            next unless r.iris_resource?
            r.load_metadata
          end
          puts 'Done loading metadata'
        end


        # Generate file history metadata
        def generate_history(resources)
          puts 'Generating file history and checksums...'
          resources.each do |r|
            next if r.ignored? || !r.in_collections_dir? || r.instance_of?(Middleman::Sitemap::Extensions::RedirectResource) || r.in_metadata_dir?
            r.add_file_history
          end
        end


        def generate_text(resources, force_regenerate=false)
          puts 'Generating file text for indexing...'
          resources.each do |r|
            next if r.ignored? || !r.in_collections_dir? || r.instance_of?(Middleman::Sitemap::Extensions::RedirectResource) || r.in_metadata_dir?
            r.rip_text_to_file
          end
        end


        def generate_thumbnails(resources, force_regenerate=false)
          puts 'Generating thumbnails...'
          resources.each do |r|
            next if r.ignored? || !r.in_collections_dir? || r.instance_of?(Middleman::Sitemap::Extensions::RedirectResource) || r.in_metadata_dir?
            r.generate_thumbnail(force_regenerate)
          end
        end


        def generate_rss(app, limit=100)
          puts 'Generating RSS feed...'

          rss = RSS::Maker.make("atom") do |maker|
            maker.channel.author = app.extensions[:iris].options[:organization_name]
            maker.channel.updated = Time.now.to_s
            maker.channel.about = app.extensions[:iris].options[:site_name]
            maker.channel.title = "#{app.extensions[:iris].options[:site_name]} - RSS Feed"

            app.sitemap.resources.select{|r| r.item?}.first(limit).each do |r|
              maker.items.new_item do |entry|
                entry.link = r.permalink
                entry.title = r.best_title
                entry.updated = r.last_timestamp&.to_s || r.mtime&.to_s || Time.now.to_s
              end
            end
          end

          root = site_root(app)
          root&.create_metadata_directory

          filename = "#{root.metadata_directory_path}/index.atom"
          File.open(filename, 'w'){|f| f.write(rss)}
          return nil
        end


        def rss_url(app)
          return "#{site_root(app).permalink}.metadata/index.atom"
        end


        def generate_oai(app)
          resources = app.sitemap.resources.select{|r| r.iris_resource? && r.item?}

          builder = Nokogiri::XML::Builder.new do |xml|
            xml.Repository(
              'xmlns' => 'http://www.openarchives.org/OAI/2.0/static-repository',
              'xmlns:oai' => 'http://www.openarchives.org/OAI/2.0/',
              'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
              'xsi:schemaLocation' => 'http://www.openarchives.org/OAI/2.0/static-repository http://www.openarchives.org/OAI/2.0/static-repository.xsd'
            ) do

              xml.Identify {
                xml['oai'].repositoryName app.extensions[:iris].options[:site_name]
                xml['oai'].baseUrl app.extensions[:iris].options[:oai_static_repository_gateway_url] || oai_url(app)
                xml['oai'].protocolVersion '2.0'
                app.extensions[:iris].options[:admin_email].split(',').each do |email|
                  xml['oai'].adminEmail email.strip
                end
                xml['oai'].earliestDatestamp resources.sort{|r| r.first_timestamp&.to_i}.first.first_timestamp
                xml['oai'].granularity 'YYYY-MM-DDThh:mm:ssZ'
              }

              xml.ListMetadataFormats {
                xml['oai'].metadataPrefix 'oai_dc'
                xml['oai'].schema 'http://www.openarchives.org/OAI/2.0/oai_dc.xsd'
                xml['oai'].metadataNamespace 'http://www.openarchives.org/OAI/2.0/oai_dc/'
              }

              xml.ListRecords('metadataPrefix' => 'oai_dc') do
                resources.each do |resource|
                  xml['oai'].record {
                    xml['oai'].header {
                      xml['oai'].identifier resource.uri
                      xml['oai'].datestamp resource.last_timestamp.iso8601
                    }
                    xml['oai'].metadata {
                      xml['oai'].dc(
                        'xmlns:oai_dc' => 'http://www.openarchives.org/OAI/2.0/oai_dc/',
                        'xmlns:dc' => 'http://purl.org/dc/elements/1.1/',
                        'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                        'xmlns:schemaLocation' => 'http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd'
                      ) do

                        resource.to_vocabulary('dcmes', resource.to_vocabulary('dc')).each do |k, v|
                          if v.instance_of?(Array) || v.instance_of?(Hashie::Array)
                            v.uniq.each do |array_v|
                              xml['dc'].send(k.split(':').last, stringify_nested_property(array_v))
                            end
                          elsif v.instance_of?(Hash) || v.instance_of?(Middleman::Util::EnhancedHash)
                            xml['dc'].send(k.split(':').last, stringify_nested_property(v))
                          else
                            xml['dc'].send(k.split(':').last, v)
                          end
                        end

                      end
                    }
                  }
                end
              end

            end
          end

          root = site_root(app)
          root&.create_metadata_directory
          filename = "#{root.metadata_directory_path}/oai-pmh.xml"
          File.open(filename, 'w'){|f| f.write(builder.to_xml)}
          return nil
        end


        def oai_url(app)
          return "#{site_root(app).permalink}.metadata/oai-pmh.xml"
        end


        def generate_rdf(app)
          resources = iris_resources(app).select{|r| r.collection? || r.item? || (r.page? && !r.in_collections_dir?)}
          jsonld = {
            '@context' => jsonld_context(app),
            '@graph' => resources.map{|r| {'@id' => r.uri, '@type' => r.rdf_class_uris }.deep_merge(r.rdf_properties) }
          }
          graph = RDF::Graph.new << JSON::LD::API.toRdf(jsonld)
          ttl = graph.dump(:ttl, prefixes: vocabularies(app))
          ntriples = graph.dump(:ntriples, prefixes: vocabularies(app))

          root = site_root(app)
          root&.create_metadata_directory

          File.open("#{root.metadata_directory_path}/index.jsonld", 'w'){|f| f.write(jsonld.to_json)}
          File.open("#{root.metadata_directory_path}/index.ttl", 'w'){|f| f.write(ttl)}
          File.open("#{root.metadata_directory_path}/index.nt", 'w'){|f| f.write(ntriples)}

        end


        def rdf_url(app, ext)
          return "#{site_root(app).permalink}.metadata/index.#{ext}"
        end


        def generate_marc(app)
          marc_records = []
          iris_resources(app).select{|r| r.item?}.each do |r|
            m = MARC::Record.new_from_hash(r.to_marc_in_json)
            record_length = "%05d" % m.to_marc.length
            bibliographic_level = if r.collection? then 'c' else 'm' end # c is collection, m is monograph/item
            base_address = "%05d" % (m.leader.length + (12 * m.fields.length))
            m.leader = "#{record_length}np#{bibliographic_level}a 22#{base_address}8u 4500" # Leader format: https://www.loc.gov/marc/bibliographic/bdleader.html
            marc_records << m
          end

          root = site_root(app)
          root&.create_metadata_directory

          builder = Nokogiri::XML::Builder.new do |xml|
            xml.collection('xmlns' => 'http://www.loc.gov/MARC21/slim') do
              marc_records.each do |r|
                xml << r.to_xml.to_s
              end
            end
          end
          File.open("#{root.metadata_directory_path}/index.mrc.xml", 'w'){|f| f.write(builder.to_xml)}

          File.open("#{root.metadata_directory_path}/index.mrc", 'w') do |f|
            marc_records.each do |m|
              f.puts m.to_marc + "\r\n\r\n"
            end
          end

        end


        def generate_index(app)
          index = []
          fields = []
          iris_resources(app).select{|r| r.collection? || r.item? || (r.page? && !r.in_collections_dir?)}.each do |r|
            puts "Indexing #{r.page_id}"
            thumbnail = r.thumbnail_url
            if thumbnail.blank?
              thumbnail = r.files_in_same_directory.select{|child| child.thumbnail?}.first&.thumbnail_url
            end

            doc = r.rdf_properties.select{|k, v| r.best_index_rules[:properties].include?(k)}
            fields << doc.keys

            doc.merge!({
              id: r.uri,
              bt: r.best_title,
              bd: r.best_description,
              bc: r.best_creator,
              sc: r.index_scopes.keys, # Scopes
              co: [r.collection&.best_title, r.collection&.permalink], # Collection
              tx: r.index_text, # Text
              tn: thumbnail, # thumbNail
              i: r.icon, # Icon class
              ch: [] # Children
            })

            r.files_in_same_directory.each do |child|
              time = Time.now
              child_rdf_properties = child.rdf_properties.select{|k, v| r.best_index_rules[:properties].include?(k)}
              fields << child_rdf_properties.keys

              doc[:ch] << {
                id: child.uri,
                bt: child.best_title,
                bd: child.best_description,
                bc: child.best_creator,
                tx: child.index_text,
                i: child.icon
              }.merge(child_rdf_properties)
            end
            doc.delete_if{|k,v| v.blank?}
            doc[:ch]&.delete_if{|v| v.blank?}
            index << doc
            fields += (doc[:ch]&.map{|child| child.keys} || [])
            fields += r.files_in_same_directory.map{|child| child.rdf_properties.select{|k, v| r.best_index_rules[:properties].include?(k)}.keys}
          end
          root = site_root(app)
          root&.create_metadata_directory

          condensed_index = index.to_json
          tokens = {
            '@u@' => app.extensions[:iris].options[:root_url] || '$URL$',
          }
          fields.flatten.uniq.select{|field| field.present?}.each_with_index do |field, i|
            tokens["@#{i}@"] = field
          end
          tokens.each do |k,v|
            condensed_index.gsub!("\"#{v.to_s}\"", "\"#{k}\"")
          end
          json = {
            tokens: tokens,
            docs: JSON.parse(condensed_index)
          }.to_json
          filename = "#{root.metadata_directory_path}/index.json"
          File.open(filename, 'w'){|f| f.write(json)}
          puts "Index file is #{file_size(filename)} at #{filename}"
          return nil
        end


        def search_index_url(app)
          return "#{site_root(app).permalink}.metadata/index.json"
        end


      end # END MODULE SingletonMethods
    end # END MODULE ResourceProcessingExtensions
  end # END MODULE Iris
end
