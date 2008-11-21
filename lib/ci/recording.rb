module CI
  class Recording < Asset
    api_attr_accessor :tracks, :files, :ISRC, :Duration
    api_attr_accessor :LabelName, :Producers, :Mixers
    api_attr_accessor :Composers, :Lyricists
    api_attr_accessor :MainArtist, :FeaturedArtists, :Artists
    has_many          :tracks
    has_many          :files
    alias_method :id, :isrc
    self.base_url = "recording/isrc"

    def initialize parameters = {}
      super
      @files = []
      @tracks = []
    end

    def newest_track
      get url('newest')
    end
  end

  #TODO add methods to get encodings etc.
end