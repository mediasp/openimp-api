class CI::File < CI
  ci_properties :Id, :MimeMajor, :MimeMinor, [:SHA1DigestBase64, :sha1_digest_base64], :FileSize, :__REPRESENTATION__
  
  self.uri_path = '/filestore'
  attr_writer :data

  def self.new_from_data(data, mime_type=nil)
    self.new({}, data, mime_type)
  end
  
  def self.new_from_file(filename, mime_type=nil)
    self.new({}, ::File.read(filename), mime_type)
  end
  
  def data
    retrieve if !@data
    @data
  end
  
  def initialize(params={}, data=nil, mime_type=nil)
    super(params)
    self.data=data
    self.mime_type=mime_type
  end
  
  def mime_type
    "#{mime_major}/#{mime_minor}"
  end
  
  def mime_type=(mime)
    mime = mime.split('/')
    mime_major, mime_minor = *mime
  end
  
  def url
    __representation__
  end
  
  def store
    do_request(:put, '/', {'Content-type' => mime_type}, data)
  end
  
  def retrieve
    data = do_request(:get, "/#{id}/retrieve") do |response|
      response.body
    end
  end
  
  def delete
    do_request(:delete, "/#{id}")
    self.data = nil
  end
  
  #TODO sort out saving updated MIME TYPE without resending data. Perhaps use a HEAD request?
  
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