module Middleman::Cli
  class CheckForProperty < Thor::Group
    include Thor::Actions

    check_unknown_options!

    class_option :properties,
                required: true,
                default: nil,
                desc: 'The properties to look for.'

    class_option :directory,
                default: nil,
                desc: 'A specific directory in which to look for the properties.'

    class_option :static_files,
                default: false,
                desc: 'Whether to check static files for the properties rather than just parent items.'


    def check_for_property
      @app = ::Middleman::Application.new do
        config[:mode] = :build
        config[:iris_cli] = :check_for_property
        ::Middleman::Logger.singleton(1, false)
      end

      start_time = Time.now
      puts "Starting check_for_property at #{Time.now}"

      Middleman::Sitemap::Resource.iris_resources(@app).each do |r|
        properties = [options[:properties]].flatten
        properties.each do |p|
          r.has_property?(p)
        end
      end

      puts "Finished check_for_property at #{Time.now} (#{Time.now-start_time} seconds)"
    end


    Base.register(self, 'check_for_property', 'check_for_property [options]', 'Check items to see which are missing a specific RDF metadata property')
  end
end
