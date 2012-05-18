require 'ci/assets'
require 'pathname'

module CI
  # A +FileToken+ is used to control access to a file stored on the server.
  class FileToken < Asset
    attributes :Id, :URL, :PlayURL, :RedirectWhenExpiredUrl, :SuccessfulDownloads, :AttemptedDownloads, :MaxDownloadAttempts, :MaxDownloadSuccesses
    attributes :file

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
    attr_accessor :content
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
  end

  class File::Video < File
  end
end

