require 'ci/assets'
require 'pathname'

module CI
  # A +FileToken+ is used to control access to a file stored on the server.
  class FileToken < Asset
    attributes :Id, :URL, :PlayURL, :RedirectWhenExpiredUrl, :SuccessfulDownloads, :AttemptedDownloads, :MaxDownloadAttempts, :MaxDownloadSuccesses
    attributes :file

    def self.path_components(instance=nil)
      if instance
        ['filetoken', instance.id] if instance.id
      else
        ['filetoken']
      end
    end


    # The MFS API exposes a FileToken creation via several different URLs. However we will never want to create
    # a file token that we do not already have a file to hand, and hence we only use the FileStore URL.
    def self.create(file, properties = {})
      MediaFileServer.post(file.path_components('createfiletoken'), properties)
    end

    # As an alternative a FileToken object can be created and the appropriate values set, then the save method
    # called which creates the token on the server and its details loaded.
    def save
      FileToken.create file, :RedirectWhenExpiredUrl => redirect_when_expired_url, :Unlimited => unlimited, :MaxDownloadAttempts => max_download_attempts, :MaxDownloadSuccesses => max_download_successes
    end

    [:Unlimited, :Valid].each do |m|
      class_eval <<-METHODS
        def #{make_ci_method_name(m)}
          @parameters[#{m.inspect}]
        end

        def #{make_ci_method_name(m)}= status
          @parameters[#{m.inspect}] = [1, true].include?(status)
        end
      METHODS
    end
  end


  class File < Asset
    attributes    :Id, :MimeMajor, :MimeMinor, :SHA1DigestBase64, :UploaderIP, :Stored, :FileSize, :crc32
    attr_writer   :content
    attr_reader   :file_name

    def self.path_components(instance=nil)
      if instance
        ['filestore', instance.id] if instance.id
      else
        ['filestore']
      end
    end

    def self.disk_file(name, mime_type)
      new(:mime_type => mime_type, :content => ::File.read(name), :file_name => name)
    end

    def mime_type
      "#{mime_major}/#{mime_minor}"
    end

    # These are mime-type normalizations which are required in order to make mime types acceptable to the CI API
    NORMALIZE_MIME_TYPE = {
      'image/pjpeg' => 'image/jpeg'
    }

    def mime_type=(mime_type)
      mime_type = NORMALIZE_MIME_TYPE[mime_type] || mime_type
      self.mime_major, self.mime_minor = *mime_type.split("/")
    end

    def content
      @content ||= retrieve_content
    end

    def file_name=(name)
      @file_name = (Pathname.new(name.to_s) rescue name)
    end

    # Retrieve the data content associated with this file
    def retrieve_content
      @content = get_octet_stream('retrieve')
    end

    # Performs an +MFS::File::Request::Store+ operation on the server, creating a new file.
    def store
      multipart_post do
        [ "Content-Disposition: form-data; name=\"file\"; filename=\"#{file_name.basename rescue "null"}\"\r\nContent-Type: #{mime_type}\r\n\r\n#{content}",
          "Content-Disposition: form-data; name=\"MimeMajor\"\r\n\r\n#{mime_major}",
          "Content-Disposition: form-data; name=\"MimeMinor\"\r\n\r\n#{mime_minor}"
          ]
      end
    end

    def store!
      replace_with! store
    end

    def create_file_token(unlimited = false, attempts = 2, successes = 2)
      FileToken.create self, :Unlimited => unlimited, :MaxDownloadAttempts => attempts, :MaxDownloadSuccesses => successes
    end

    def change_meta_data
      replace_with! post(:MimeMajor => mime_major, :MimeMinor => mime_minor)
    end

    def contextual_methods
      @contextual_methods ||= get('contextualmethod')
    end

    def sub_type(mime_type)
      post({ :NewType => "MFS::File::#{/\//.match(mime_type).pre_match.capitalize}" }, 'becomesubtype')
    end

  protected
    def replace_with! file
      @content = file.instance_variable_get(:@content)
      @file_name = file.instance_variable_get(:@file_name)
      super
    end
  end


  class File::Audio < File
    attributes    :BitRate, :encoding
    attributes    :Duration, :type => :duration
    collections   :tracks
  end


  class File::Image < File
    attributes    :width, :height

    RESIZE_METHODS = [ 'NOMODIFIER', 'EXACT', 'SQUARE', 'SMALLER', 'LARGER' ]
    RESIZE_TYPES = { 'jpeg' => 'jpg', 'png' => 'png', 'tiff' => 'tiff', 'gif' => 'gif', 'bmp' => 'bmp' }

    def resize(width, height, mode = :NOMODIFIER, properties = {})
      MediaFileServer.post(path_components('contextualmethod', 'Resize'), properties.merge(:targetX => width, :targetY => height, :resizeType => "IMAGE_RESIZE_#{mode}", :Synchronous => 1))
    end

    def resize! width, height, mode = :NOMODIFIER, properties = {}
      replace_with! resize(width, height, mode, properties)
    end
  end

  class File::Video < File
  end
end
