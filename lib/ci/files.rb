module CI
  # A +FileToken+ is used to control access to a file stored on the server.
  class FileToken < Asset
    base_url      :filetoken
    attributes    :URL, :PlayURL, :RedirectWhenExpiredUrl, :SuccessfulDownloads, :AttemptedDownloads, :MaxDownloadAttempts, :MaxDownloadSuccesses
    attributes    :file

    # The CI API exposes a FileToken creation via several different URLs. However we will never want to create
    # a file token that we do not already have a file to hand, and hence we only use the FileStore URL.
    def self.create file, properties = {}
      MediaFileServer.post file.url('createfiletoken'), properties
    end

    # As an alternative a FileToken object can be created and the appropriate values set, then the save method
    # called which creates the token on the server and its details loaded.
    def save
      FileToken.create file, :RedirectWhenExpiredUrl => redirect_when_expired_url, :Unlimited => unlimited, :MaxDownloadAttempts => max_download_attempts, :MaxDownloadSuccesses => max_download_successes
    end

    [:Unlimited, :Valid].each do |m|
      class_eval <<-METHODS
        def #{m.to_method_name}
          @parameters[#{m}]
        end

        def #{m.to_method_name}= status
          @parameters[#{m}] = [1, true].include?(status)
        end
      METHODS
    end
  end


  class File < Asset
    base_url      :filestore
    attributes    :MimeMajor, :MimeMinor, :SHA1DigestBase64, :UploaderIP, :Stored, :FileSize
    attr_writer   :content

    def self.disk_file name, mime_type
      new :mime_type => mime_type, :content => ::File.read(name)
    end

    def mime_type
      "#{mime_major}/#{mime_minor}"
    end

    def mime_type= specifier
      self.mime_major, self.mime_minor = *specifier.split("/")
    end

    def content
      @content ||= retrieve_content
    end

    # Retrieve the data content associated with this file
    def retrieve_content
      @content = get_octet_stream('retrieve')
    end

    # Performs an +API::File::Request::Store+ operation on the server, creating a new file.
    def store
      put mime_type, content
    end

    def store!
      replace_with! store
    end
    
    def create_file_token unlimited = false, attempts = 2, successes = 2
      FileToken.create self, :Unlimited => unlimited, :MaxDownloadAttempts => attempts, :MaxDownloadSuccesses => successes
    end

    def change_meta_data
      replace_with! post(:MimeMajor => mime_major, :MimeMinor => mime_minor)
    end

    def contextual_methods
      @contextual_methods ||= get('contextualmethod')
    end

    def sub_type mime_type
      post({ :NewType => "API::File::#{/\//.match(mime_type).pre_match.capitalize}" }, 'becomesubtype')
    end

  protected
    def replace_with! file
      @content = nil
      super
    end
  end


  class File::Audio < File
    attributes    :BitRate, :encoding
    collections   :tracks
  end


  class File::Image < File
    attributes    :width, :height

    RESIZE_METHODS = [ 'NOMODIFIER', 'EXACT', 'SQUARE', 'SMALLER', 'LARGER' ]
    RESIZE_TYPES = { 'jpeg' => 'jpg', 'png' => 'png', 'tiff' => 'tiff', 'gif' => 'gif' }

    def resize width, height, mode = :NOMODIFIER, properties = {}
      MediaFileServer.post(url('contextualmethod/Resize'), properties.merge(:targetX => width, :targetY => height, :resizeType => "IMAGE_RESIZE_#{mode}", :Synchronous => 1))
    end

    def resize! width, height, mode = :NOMODIFIER, properties = {}
      replace_with! resize(width, height, mode, properties)
    end
  end

  class File::Video < File
  end
end