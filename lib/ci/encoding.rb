module CI
  class Encoding < Asset
    api_attr_accessor :Codec, :Family, :PreviewLength, :Channels, :Bitrate, :Description, :Name
    self.base_url = 'encoding'
    @@encodings = nil

    def self.synchronize
      @@encodings = MediaFileServer.get(url nil)
    end

    def self.encodings
      @@encodings.dup rescue nil
    end

    # We use a custom constructor to automatically load the correct object from the
    # CI MFS system if the parameters to +new+ include a +name+.
    def self.new parameters={}, *args
      super parameters.merge(:Id => parameters[:Name] || parameters[:name], :Name => nil, :name => nil), *args
    end
  end
end