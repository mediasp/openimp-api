module CI::Repository

  class File < Base

    def model_class ; CI::File ; end

    def path_components(instance=nil)
      if instance
        ['filestore', instance.id] if instance.id
      else
        ['filestore']
      end
    end

    def mfs_class_name
      "MFS::File"
    end

    # Performs an +MFS::File::Request::Store+ operation on the server, creating a new file.
    def store(file)
      @client.multipart_post do
        [
          "Content-Disposition: form-data; name=\"file\"; filename=\"#{file.file_name.basename rescue "null"}\"\r\nContent-Type: #{file.mime_type}\r\n\r\n#{file.content}",
          "Content-Disposition: form-data; name=\"MimeMajor\"\r\n\r\n#{file.mime_major}",
          "Content-Disposition: form-data; name=\"MimeMinor\"\r\n\r\n#{file.mime_minor}",
          "Content-Disposition: form-data; name=\"FileClass\"\r\n\r\n#{mfs_class_name}"
          ]
      end
    end

    def disk_file(name, mime_type)
      new(:mime_type => mime_type, :content => ::File.read(name), :file_name => name)
    end

    # Preferred way to download bigger files - avoids bringing the whole file into
    # memory at once.
    def download_to_file(ci_file, filename)
      raise NotImplementedError
      # needs response yielding to be added to the client first
      ::File.open(filename, 'wb') do |file|
        retrieve(ci_file) do |response|
          response.read_body {|segment| file << segment}
        end
      end
    end

    # fetches the contents of a CI::File in to the model
    def set_content_for(file)
      file.tap do |f|
        f.content = retrieve(f)
      end
    end

    # returns the raw binary data for a CI::File as a string
    def retrieve(file, &block)
      @client.get(path_for(file) + '/retrieve', :json => false, &block)
    end

    # a list of the contextual methods for a CI::File
    def contextual_methods(file)
      @client.get(path_for(file) + '/contextualmethod')
    end

    def change_meta_data(file)
      mime_data = {:MimeMajor => mime_major, :MimeMinor => mime_minor}
      result_file = @client.post(path_for(file), mime_data)
      file.send(:replace_with!, result_file)
      file
    end

  end
end
