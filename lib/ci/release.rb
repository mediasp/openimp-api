module CI
  class Release < Asset
    #TODO code to convert ISO Durations and dates / times to ruby objects.
    api_attr_accessor :LabelName, :CatalogNumber, :ReleaseType, :UPC, :ParentalWarningType, :PriceRangeType
    api_attr_accessor :ReferenceTitle, :SubTitle, :imagefrontcover, :Duration
    api_attr_accessor :MainArtist, :DisplayArtist, :FeaturedArtists, :Artists
    api_attr_accessor :Genres, :SubGenres
    api_attr_accessor :PLineYear, :PLineText, :CLineYear, :CLineText
    api_attr_accessor :tracks, :TrackCount
    has_many          :tracks
    has_many          :Artists
    has_many          :FeaturedArtists
    has_many          :DisplayArtists
    has_many          :Genres
    has_many          :SubGenres
    references        :imagefrontcover
    self.base_url = "release/upc"
  end
end