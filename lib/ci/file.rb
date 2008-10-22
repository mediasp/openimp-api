#Represents an object in the CI MFS filestore. CI::Files have the following properties, in addition to those inherited from the CI Base class:
#* id
#* mime_major
#* mime_minor
#* sha1_digest_base64
#* file_size
#* stored
#
#Documentation for all these properties can be found in CI's API documentation.

class CI::File < CI
  ci_properties :Id, :MimeMajor, :MimeMinor, [:SHA1DigestBase64, :sha1_digest_base64], :FileSize, :Stored  
  self.uri_path = '/filestore'

  #Create a new file object from a string of data bytes. The mime_type of the data should be passed as a string.
  def self.new_from_data(data, mime_type=nil)
    self.new({}, data, mime_type)
  end
  
  #Create a new file object from a string path to a file on disk. The mime_type of the data should be passed as a string.
  def self.new_from_file(filename, mime_type=nil)
    self.new({}, ::File.read(filename), mime_type)
  end
        
  def initialize(params={}, data=nil, mime_type=nil) #:nodoc:
    super(params)
    self.data=data
    self.mime_type=mime_type if mime_type
  end
  
  #Returns a boolean value reflecting whether this file object has been stored remotely. Note that this doesn't necessarily reflect whether the file held locally differs from the remote copy at all.
  def stored?
    stored ? true : false
  end
  
  #Returns the mime type of the file. Wraps the mime_major and mime_minor methods of the CI API
  def mime_type
    "#{mime_major}/#{mime_minor}"
  end
  
  #Return the file data stored in the CI API. this is memoiszed after the first request
  def data
    @data ||= retrieve
  end
  
  #Set the data stored in this File object.
  def data=(data)
    unless @data == data
      @data = data
      @data_changed = true
    end
    return @data
  end
  
  #Set the mime-type of the data. Wraps the mime_major and mime_minor properties and takes a string.
  def mime_type=(mime)
    self.mime_major, self.mime_minor = *mime.split('/')
  end
  
  #Store this File object remotely in the CI MFS API. If the local file does not differ from the remote one, this will do nothing.
  def store
    if @data_changed
      do_request(:put, "/", {'Content-type' => mime_type}, data)
      @data_changed = false
    end
  end
  
  #Retrieve the file data stored remotely. normally CI::File#data should be used for this task, however retrieve will always make a request, returning the file data, and will update the locally cached data returned by CI::File#data.
  def retrieve
    unless @data && !@data_changed
      @data = do_request(:get, "/#{id}/retrieve") do |response|
        response.body
      end
      @data_changed = nil
    end
    return @data
  end
  
  #Create a CI::FileToken for this file.
  def create_token(unlimited=false, attempted_downloads=2, successful_downloads=2)
    self.store
    post_data = unlimited ? {:Unlimited => '1'} : {:MaxDownloadAttempts => attempted_downloads, :MaxDownloadSuccesses => successful_downloads}
    CI::FileToken.do_request(:post, "/#{id}/createfiletoken", nil, nil, post_data)
  end
    
  #Cast this File as a subclass of CI::File. Will raise an exception unless the file data is of a compatible mime_type. Returns an instance of the class we are casting to - this doesn't modify the current instance in place, as that would be plain silly.
  def cast_as(klass)
    self.store
    raise "You cannot re-cast a subclass of CI::FILE" unless self.class == CI::File || self.class == klass #cast_as(self.class) is used when initializing File subclasses in order to inform the server and get additional params.
    if klass == CI::File::Image
      raise "This is not an image file of a compatible type" unless mime_major == 'image' && ['jpeg', 'gif', 'png', 'tiff'].include?(mime_minor)
    elsif klass == CI::File::Audio
      raise "This is not an audio file of a compatible type" unless mime_major == 'audio' && [] #finish this
    else
      raise "You can't cast an instance of CI::File to an instance of #{klass.name}"
    end
    klass.do_request(:post, "/#{id}/becomesubtype", nil, nil, {:NewType => klass.name.sub('CI', 'API')})
  end
  
end