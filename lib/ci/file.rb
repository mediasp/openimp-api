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
    api_attr_reader   :Stored, :MimeMajor, :MimeMinor, :FileSize
    api_attr_reader   :SHA1DigestBase64, :UploaderIP, :Stored
    self.base_url = "/filestore"

    def initialize parameters = {}, data = ""
      super
      @dirty = false
      @original_mime_type = mime_type
      @content = data
    end
  
    #Store this File object remotely in the CI MFS API. If the local file does not differ from the remote one, this will do nothing.
    def store
      if @data_changed
        do_request(:post, "/", {'Content-type' => mime_type}, nil ,data)
        @data_changed = false
        get_meta #CI API infers some properties of the file. We need these locally!
        return @data
      end
    end

    def content
      @content
    end

    def content= new_content
      unless new_content == content
        @dirty = true
        @content = new_content
      end
    end

    def mime_type
      "#{mime_major}/#{mime_minor}"
    end

    def mime_type= specifier
      mime_major, mime_minor = specifier.split("/")
    end

    # Retrieve the data content associated with this file
    def retrieve_content
      @content = get_octet_stream
      @dirty = false
    end

    # Performs an +API::File::Request::Store+ operation on the server.
    def store
      file = add_contents
      file.become_sub_type rescue file
    end
    
    def create_file_token unlimited = false, attempts = 2, successes = 2
      FileToken.create self, {  :Unlimited => unlimited,
                                :MaxDownloadAttempts => attempts,
                                :MaxDownloadSuccesses => successes }
    end

    # Add contents to the file on the server, returning a new file object when necessary
    def add_contents
      if @dirty then
        response = put(mime_type, content)
        @dirty = false
      end
      response || self
    end

    def become_sub_type
      case MimeMajor
      when 'image'
        case MimeMinor
        when 'jpeg', 'gif', 'tiff', 'png'
          post :NewType => 'API::File::Image'
        end
      when 'audio'
        case MimeMinor
        when 'mp3', 'wav', 'flac', 'wma'
          post :NewType => 'API::File::Audio'
        end
      else
        raise "Cannot use file as #{MimeMajor}/#{MimeMinor}"
      end
    end

    def change_meta_data
      post :MimeMajor => mime_major, :MimeMinor => mime_minor
    end

    def enumerate_contextual_methods
      get url(file.id, 'contextualmethod')
    end
  end

  class File::Audio < File
    api_attr_reader :Tracks, :BitRate, :encoding
  end

  class File::Image < File
    api_attr_reader :width, :height

    RESIZE_METHODS = [ 'NOMODIFIER', 'EXACT', 'SQUARE', 'SMALLER', 'LARGER' ]
    RESIZE_TYPES = { 'jpeg' => 'jpg', 'png' => 'png', 'tiff' => 'tiff', 'gif' => 'gif' }

    def resize width, height, constraint = :nomodifier, type = nil, synchronous = nil, token_properties = {}
      synchronoous = properties[:synchronous]
      post url('resize'), properties
    end
  end
end