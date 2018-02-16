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
        if self.last_checksum != self.current_checksum && self.in_collections_dir? && !self.ignored?
          history = self.file_history
          history[Time.now] = {
            'timestamp' => Time.now,
            'checksum' => self.current_checksum
          }
          create_metadata_directory
          File.open(file_history_path, 'w'){|f| f.write history.to_yaml}
        end
      end


      def text_file_path
        "#{self.dirname}/_metadata/#{self.filename}.txt"
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
        return nil if !in_collections_dir? || self.ignored?

        text = nil

        # First see if text file exists and if file checksum is the same
        create_metadata_directory
        if File.exist?(text_file_path) && (self.current_checksum == self.last_checksum)
          text = File.read(text_file_path)

        # Otherwise, rip text and save it before returning
        else
          if page?
            # Rip rendered HTML page content using Nokogiri
            doc = Nokogiri::HTML(self.render)
            text = doc.css(iris_option(:html_text_indexing_selector)).text
            File.open(text_file_path, 'w'){|f| f.write text}
          elsif pdf?
            # Rip PDF text using pdf-reader library
            reader = PDF::Reader.new(self.source_file)
            page_text = []
            reader.pages.each do |page|
              page_text << page.text
            end
            text = page_text.join("\n")
            File.open(text_file_path, 'w'){|f| f.write text}
          elsif word_doc? && Dir.exists?(iris_option(:libreoffice_dir))
            # Rip Office documents using LibreOffice CLI convert tool
            system("\"#{iris_option(:libreoffice_dir)}/soffice.exe\" --headless --convert-to txt \"#{self.source_file}\" --outdir \"#{metadata_directory_path}\"")
            system("mv \"#{text_file_path.gsub(self.ext, '')}\" \"#{text_file_path}\"")
          elsif spreadsheet? && Dir.exists?(iris_option(:libreoffice_dir))
            # Rip spreadsheets using the Roo library
            workbook = Roo::Spreadsheet.open(self.source_file)
            text = ''
            workbook.sheets.each do |sheet_name|
              text += workbook.sheet(sheet_name).to_csv
            end
            File.open(text_file_path, 'w'){|f| f.write text}
          elsif powerpoint? && Dir.exists?(iris_option(:libreoffice_dir))
            # Rip Powerpoint files to PDF using LibreOffice CLI and then from PDF to txt using pdf-reader library
            system("\"#{iris_option(:libreoffice_dir)}/soffice.exe\" --headless --convert-to pdf \"#{self.source_file}\" --outdir \"#{metadata_directory_path}\"")
            pdf_path = text_file_path.gsub(self.ext+'.txt', '.pdf')
            reader = PDF::Reader.new(pdf_path)
            page_text = []
            reader.pages.each do |page|
              page_text << page.text
            end
            text = page_text.join("\n")
            File.open(text_file_path, 'w'){|f| f.write text}
            File.delete(pdf_path)
          elsif textfile?
            # Copy plain text files
            FileUtils.cp(self.source_file, text_file_path)
          end
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
          self.data.dig('iris', 'permalink') || iris_option(:root_url) + @app.sitemap.resources.select{|r| r.source_file == self.thumbnail_path}.first&.url
        end
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

        if self.powerpoint? || self.word_doc? || self.spreadsheet?
          system("\"#{iris_option(:libreoffice_dir)}/soffice.exe\" --convert-to pdf --outdir \"#{self.dirname}\" \"#{self.source_file}\"")
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
        rules[:properties] = iris_option(:index_default_properties) || rules[:properties]
        rules[:file_text] = iris_option(:index_default_file_text) || rules[:file_text]

        # File regex default
        rules[:properties] = iris_option(:index_for_files_like)&.select{|r| self.page_id.match(r[:regex])}&.last&.dig(:properties) || rules[:properties]
        rules[:file_text] = iris_option(:index_for_files_like)&.select{|r| self.page_id.match(r[:regex])}&.last&.dig(:file_text) || rules[:file_text]

        # Doc-specific
        rules[:properties] = self.iris_value(:indexing)&.dig(:properties) || rules[:properties]
        rules[:file_text] = self.iris_value(:indexing)&.dig(:file_text) || rules[:file_text]

        return rules
      end


      def indexes
        index_hash = {}
        collections = @app.sitemap.resources.select{|r| r.site_root? || (r.collection? && self.descendant_of?(r)) }
        collections.each do |c|
          index_name = c.best_title
          index_name = @app.config[:site_name] if @app.config[:site_name].present? && c.site_root?
          index_hash[index_name] = c.permalink + '.metadata/index.json'
        end
        return index_hash
      end


      module SingletonMethods

        def build_indexes(app)
          indexes = []
          collections = []
          collections += app.sitemap.resources.select{|r| r.site_root?}
          collections += app.sitemap.resources.select{|r| r.collection?}
          collections.uniq!
          collections.each do |c|
            puts "Indexing collection #{c.dirname}"
            start_time = Time.now
            index = []
            resources = app.sitemap.resources.select{|r| !r.ignored? && r.in_collections_dir? && !r.in_metadata_dir?}
            if !c.site_root?
              resources = resources.select{|r| r.descendant_of?(c)}
            end
            resources.each do |r|
              doc = r.rdf_properties.select{|k, v| r.best_index_rules[:properties].include?(k)}
              doc.merge!({
                id: r.uri,
                text: r.index_text
              })
              doc.delete_if{|k,v| v.blank?}
              index << doc
            end
            c.create_metadata_directory
            File.open("#{c.metadata_directory_path}/index.json", 'w'){|f| f.write(index.to_json)}
            puts "Finished in #{Time.now - start_time}"
            indexes << index
          end
          return indexes
        end


      end # END MODULE SingletonMethods
    end # END MODULE ResourceProcessingExtensions
  end # END MODULE Iris
end
