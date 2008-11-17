class CI::Release < CI
  self.uri_path = '/release/upc'
  
  ci_properties *[
    :PLineYear,
    :tracks,
    :SubGenres,
    :CLineText,
    :PriceRangeType,
    :ReferenceTitle,
    :Genres,
    :FeaturedArtists,
    :Imagefrontcover,
    :SubTitle,
    :Duration,
    :ParentalWarningType,
    :LabelName,
    :CLineYear,
    :ReleaseType,
    :CatalogNumber,
    :PLineText,
    :MainArtist,
    :DisplayArtist, 
    :UPC,
    :TrackCount,
    :artists
  ]
  
  def artists
    @params[:artists] || []
  end
  
  #TODO code to convert ISO Durations and dates / times to ruby objects.
  #Do we need to keep exceptional_mappings for :Imagefrontcover?
  #use ci property name when defining relations?
  #use  relation definition stuff where needed.
  #default classes for some relations?
  ci_has_many :tracks
  ci_has_one :Imagefrontcover
end