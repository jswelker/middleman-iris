module Middleman
  module Iris
    module ResourceValidatorExtensions

      def self.included(base)
        base.extend(Middleman::Iris::ResourceValidatorExtensions::SingletonMethods)
      end


      # def before_build
      #   validate_collections
      # end

      #   def validate_collections
      #     app.sitemap.resources.each do |r|
      #       if r.data&.dig('iris', 'collection')
      #         if r.best_description.blank?
      #           raise Iris::MetadataValidationError.new('Collections must have a description', r.source_file)
      #         end
      #         if r.best_title.blank? || r.best_title == r.filename
      #           raise Iris::MetadataValidationError.new('Collections must have a title', r.source_file)
      #         end
      #       end
      #     end
      #   end
      # end
      #
      #
      # class MetadataValidationError < StandardError
      #   def initialize(message, filename)
      #     super("There was an error in the metadata of file #{filename}: #{message}")
      #   end
      # end


      module SingletonMethods

      end # END MODULE SingletoneMethods
    end # END MODULE ResourceValidatorExtensions
  end # END MODULE Iris
end
