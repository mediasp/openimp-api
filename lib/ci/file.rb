class CI::File < CI
  ci_properties :Id, :MimeMajor, :MimeMinor, :SHA1DigestBase64, :FileSize, :__REPRESENTATION__
  
  self.uri_path = '/filestore'
  attr_writer :data
  alias_method :sha1_digest_base64, :s_h_a1_digest_base64 #ActiveSupport's String#underlinize gets confused.  We'll add  a convenience method for humans.
  alias_method :sha1_digest_base64=, :s_h_a1_digest_base64= 
  
  def self.new_from_data(data, mime_type=nil)
    self.new({}, data, mime_type)
  end
  
  def self.new_from_file(filename, mime_type=nil)
    #TODO sort out reading from file and despatch to new_from_data
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
    do_request(:put, '/', {'Content-Type' => mime_type}, data)
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
  
  def cast_as()
    raise "You cannot re-cast a subclass of CI::FILE" unless self.class == CI::File
    #TODO finish cast_as method.
  end
  
end