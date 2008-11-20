#Represents an object in the CI MFS filestore. CI::Files have the following properties, in addition to those inherited from the CI Base class:
#* id
#* mime_major
#* mime_minor
#* sha1_digest_base64
#* file_size
#* stored
#
#Documentation for all these properties can be found in CI's API documentation.

module CI
  class File < Asset
    api_attr_accessor :MimeMajor, :MimeMinor
    api_attr_accessor :SHA1DigestBase64, :UploaderIP, :Stored, :FileSize
    attr_writer       :content
    self.base_url = "filestore"

    def self.disk_file(name, mime_type)
      new :mime_type => mime_type, @content => ::File.read(name)
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
      file = store
      @parameters = file.parameters
      self
    end
    
    def create_file_token unlimited = false, attempts = 2, successes = 2
      FileToken.create self, :Unlimited => unlimited, :MaxDownloadAttempts => attempts, :MaxDownloadSuccesses => successes
    end

    def change_meta_data
      post :MimeMajor => mime_major, :MimeMinor => mime_minor
    end

    def enumerate_contextual_methods
      get url(file.id, 'contextualmethod')
    end
  end

  class File::Audio < File
    api_attr_accessor :Tracks, :BitRate, :encoding
  end

  class File::Image < File
    api_attr_accessor :width, :height

    RESIZE_METHODS = [ 'NOMODIFIER', 'EXACT', 'SQUARE', 'SMALLER', 'LARGER' ]
    RESIZE_TYPES = { 'jpeg' => 'jpg', 'png' => 'png', 'tiff' => 'tiff', 'gif' => 'gif' }

    def resize width, height, properties = {}, token_properties = nil
      image = MediaFileServer.post url('resize'), properties.merge(:targetX => width, :targetY => height)
      token_properties ? FileToken.create(image, token_properties) : image
    end
  end
end