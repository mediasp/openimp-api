class CI::File < CI
  ci_properties :Id, :MimeMajor, :MimeMinor, [:SHA1DigestBase64, :sha1_digest_base64], :FileSize, :__REPRESENTATION__
  
  self.uri_path = '/filestore'

  def self.new_from_data(data, mime_type=nil)
    self.new({}, data, mime_type)
  end
  
  def self.new_from_file(filename, mime_type=nil)
    self.new({}, ::File.read(filename), mime_type)
  end
    
  def self.find(id)
    do_request(:get, "/#{id}")
  end  
    
  def initialize(params={}, data=nil, mime_type=nil)
    super(params)
    self.data=data
    self.mime_type=mime_type if mime_type
  end
  
  def mime_type
    "#{mime_major}/#{mime_minor}"
  end
  
  def data
    @data ||= retrieve
  end
  
  def data=(data)
    unless @data == data
      @data = data
      @data_changed = true
    end
    return @data
  end
  
  def mime_type=(mime)
    mime = mime.split('/')
    mime_major, mime_minor = *mime
  end
  
  def store
    if @data_changed
      do_request(:put, "/#{id}", {'Content-type' => mime_type}, data) #when id is nil the path will just be '/' which creates a new record. Clever, huh?
      @data_changed = false
    end
  end
  
  def retrieve
    unless @data && !@data_changed
      @data = do_request(:get, "/#{id}/retrieve") do |response|
        response.body
      end
      @data_changed = nil
    end
    return @data
  end
  
  def delete
    do_request(:delete, "/#{id}")
    self.data = nil
  end
  
  def cast_as(klass)
    raise "You cannot re-cast a subclass of CI::FILE" unless self.class == CI::File
    case klass
    when CI::File::Image
      raise "This is not an image file of a compatible type" unless mime_major == 'image' && ['jpeg', 'gif', 'png', 'tiff'].include?(mime_minor)
    when CI::File::Audio
      raise "This is not an audio file of a compatible type" unless mime_major == 'audio' && []
    end
    @params.merge(:new_type => 'klass.name'.sub('CI', 'API'))
    klass.do_request(:post, "#{id}/becomesubtype")
  end
  
end