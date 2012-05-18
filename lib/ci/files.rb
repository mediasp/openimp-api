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
    attr_reader   :content
    attr_reader   :file_name

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

    def file_name=(name)
      @file_name = (Pathname.new(name.to_s) rescue name)
    end

    # not being ported
    # def create_file_token(unlimited = false, attempts = 2, successes = 2)
    #   FileToken.create self, :Unlimited => unlimited, :MaxDownloadAttempts => attempts, :MaxDownloadSuccesses => successes
    # end

    # Disable this method as it has proven to cause latency issues. CI promised to
    # fix it by adding a DB index, but avoid for now. CI::Files should now be created
    # with the correct subtype by default already.
    # def sub_type(mime_type)
    #   new_class = case mime_type.split('/').first
    #   when 'image' then Image
    #   when 'audio' then Audio
    #   else File
    #   end
    #   post({ :NewType => new_class.mfs_class_name }, 'becomesubtype')
    # end

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

