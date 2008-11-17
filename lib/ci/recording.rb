module CI
  class Recording < Asset
    api_attr_reader   :tracks, :files, :ISRC, :Duration
    api_attr_reader   :LabelName, :Producers, :Mixers
    api_attr_reader   :Composers, :Lyricists
    api_attr_reader   :MainArtist, :FeaturedArtists, :Artists
  end
end