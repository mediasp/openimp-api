module CI
  class Release < Asset
    #TODO code to convert ISO Durations and dates / times to ruby objects.
    #Do we need to keep exceptional_mappings for :Imagefrontcover?
    #use ci property name when defining relations?
    #use  relation definition stuff where needed.
    #default classes for some relations?
    #ci_has_many :tracks
    #ci_has_one :Imagefrontcover
    api_attr_reader   :LabelName, :CatalogNumber, :ReleaseType, :UPC, :ParentalWarningType, :PriceRangeType
    api_attr_reader   :ReferenceTitle, :SubTitle, :imagefrontcover, :Duration
    api_attr_reader   :MainArtist, :DisplayArtist, :FeaturedArtists, :Artists
    api_attr_reader   :Genres, :SubGenres
    api_attr_reader   :PLineYear, :PLineText, :CLineYear, :CLineText
    api_attr_reader   :tracks, :TrackCount
    has_many          :tracks
    has_one           :imagefrontcover

    def artists
      @params[:artists] || []
    end
  end
end