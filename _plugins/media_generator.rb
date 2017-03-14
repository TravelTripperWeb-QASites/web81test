#-----------------------------------------------------------------------------------------
#
# This plugin read all the individual media files(old and new) and write them into single json file.
# Also it reads all the individual model instance files and write them to single json file.
# When jekyll server running all these files will be created and updated accordingly.
#
#---------------------------------------------------------------------------------------

module Jekyll
  class MediaGenerator < Generator
    # This generator is safe from arbitrary code execution.
    safe true
    
    def generate(_site)
      create_media_files  # creates image_data.json
      create_old_media # creates old_media.json
      create_model_files
    end

    private

    def definitions_dir
      File.join('_data', '_definitions')
    end

    def model_dir
      File.join('_data', '_models')
    end

    def media_dir
      File.join('_assets', 'image_data')
    end

    def old_media_dir
      File.join('_assets', 'images')
    end

    def absolute_dir(dir)
      File.expand_path(File.join(Dir.pwd, dir))
    end

    def save_json(filename, content)
      File.open("#{filename}.json", 'w') do |file|
        file.write(JSON.pretty_generate(content))
      end
    end

    def clean_file(filename)
      `rm #{filename}.json` if File.exist?("#{filename}.json")
    end

    # create old_media json for the images fetching from Github
    def create_old_media
      folder = old_media_dir
      clean_file('old_media')
      abs_folder = absolute_dir(folder)
      return [] unless File.directory? abs_folder
      old_media_data = []
      Dir[File.join(abs_folder, '/*')].each do |file|
        old_media_data << { :path => File.basename(file), :sha => '' }
      end
      save_json 'old_media', old_media_data
    end

    def create_media_files
      folder = media_dir
      file_name = 'media'
      clean_file(file_name)
      abs_folder = absolute_dir(folder)
      return unless File.directory? abs_folder
      writing_file_data = Dir[File.join(abs_folder, '*.json')].map do |file|
        data = JSON.parse File.read(file)
        data[:git_file_name] = File.join(folder, File.basename(file))
        data
      end.flatten
      save_json file_name, writing_file_data
    end

    def create_model_files
      file_name = 'models'
      clean_file(file_name)
      def_abs_folder = absolute_dir(definitions_dir)
      # If there is not a definitions directory, we have no models
      return unless File.directory? def_abs_folder
      
      # First get all of the definitions
      models_hash = Hash.new { |h, k| h[k] = [] }
      Dir[File.join(def_abs_folder, '*.json')].each do |f| 
        models_hash[File.basename(f).gsub('.json','')] = []        
      end
      
      # Then load basic instance data into the definition instance lists
      models_abs_folder = absolute_dir(model_dir)
      models_sub_folders = Dir.entries("#{models_abs_folder}/").select { |entry| File.directory? File.join(models_abs_folder, entry) and !(entry == '.' || entry == '..') }
      
      models_sub_folders.each do |sub_folder|
        Dir[File.join(models_abs_folder, sub_folder, '*.json')].map do |f|
          data = JSON.parse File.read(f)
          attrs = {}
          attrs[:name] = data['name'] if data.has_key?('name')
          attrs[:title] = data['title'] if data.has_key?('title')
          attrs[:file] = File.basename(f)
          models_hash[sub_folder.to_s] << [attrs]
        end
      end
      save_json file_name, models_hash
    end
  end
end
