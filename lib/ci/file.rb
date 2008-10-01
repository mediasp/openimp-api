class CI::File < CI
  ci_properties :Id, :MimeMajor, :MimeMinor, [:SHA1DigestBase64, :sha1_digest_base64], :FileSize, :Stored
  
  self.uri_path = '/filestore'

  def self.new_from_data(data, mime_type=nil)
    self.new({}, data, mime_type)
  end
  
  def self.new_from_file(filename, mime_type=nil)
    self.new({}, ::File.read(filename), mime_type)
  end
        
  def initialize(params={}, data=nil, mime_type=nil)
    super(params)
    self.data=data
    self.mime_type=mime_type if mime_type
  end
  
  def stored?
    stored ? true : false
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
    self.mime_major, self.mime_minor = *mime.split('/')
  end
  
  def store
    if @data_changed
      do_request(:put, "/", {'Content-type' => mime_type}, data)
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
  
  def create_token(unlimited=false, attempted_downloads=2, successful_downloads=2)
    self.store
    post_data = unlimited ? {:unlimited => '1'} : {:max_download_attempts => attempted_downloads, :max_download_successes => successful_downloads}
    CI::FileToken.do_request(:post, "/#{id}/createfiletoken", nil, nil, post_data)
  end
    
  def cast_as(klass)
    self.store
    puts "mime_major: #{mime_major}"
    puts "mime_minor: #{mime_minor}"
    raise "You cannot re-cast a subclass of CI::FILE" unless self.class == CI::File
    if klass == CI::File::Image
      raise "This is not an image file of a compatible type" unless mime_major == 'image' && ['jpeg', 'gif', 'png', 'tiff'].include?(mime_minor)
    elsif klass == CI::File::Audio
      raise "This is not an audio file of a compatible type" unless mime_major == 'audio' && [] #finish this
    else
      raise "You can't cast an instance of CI::File to an instance of #{klass.name}"
    end
    klass.do_request(:post, "/#{id}/becomesubtype", nil, nil, {:new_type => klass.name.sub('CI', 'API')})
  end
  
end