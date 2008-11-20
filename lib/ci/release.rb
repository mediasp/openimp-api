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

    def artists
      @params[:artists] || []
    end
  end
end