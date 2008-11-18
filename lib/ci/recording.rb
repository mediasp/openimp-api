module CI
  class Recording < Asset
    api_attr_reader   :tracks, :files, :ISRC, :Duration
    api_attr_reader   :LabelName, :Producers, :Mixers
    api_attr_reader   :Composers, :Lyricists
    api_attr_reader   :MainArtist, :FeaturedArtists, :Artists
    has_many          :tracks
    has_many          :files
    alias_method :id, :isrc
    alias_method :id=, :isrc=
    self.base_url = "/recording/isrc"

    def initialize
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