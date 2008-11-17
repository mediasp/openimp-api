class CI::Release < CI
  ci_properties :PLineYear, :tracks, :subgenres, :CLineText, :PriceRangeType, :ReferenceFile, :Genres, :FeaturedArtists, :Imagefrontcover, :SubTitle, :Duration, :ParentalWarningType, :LabelName, :CLineYear, :ReleaseType, :CatalogNumber, :PLineText, :MainArtist, :DisplayArtist, :UPC, :TrackCount
  #TODO code to convert ISO Durations and dates / times to ruby objects.
  #Do we need to keep exceptional_mappings for :Imagefrontcover?
  #use ci property name when defining relations?
  #use  relation definition stuff where needed.
  #default classes for some relations?
  ci_has_many :tracks
  ci_has_one :Imagefrontcover
end