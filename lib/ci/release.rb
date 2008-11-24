module CI
  class Release < Asset
    #TODO code to convert ISO Durations and dates / times to ruby objects.
    primary_key   :UPC
    base_url      :"release/upc"
    attributes    :LabelName, :CatalogNumber, :ReleaseType, :ParentalWarningType, :PriceRangeType
    attributes    :ReferenceTitle, :SubTitle, :Duration
    attributes    :MainArtist, :DisplayArtist
    attributes    :PLineYear, :PLineText, :CLineYear, :CLineText
    attributes    :TrackCount
    collections   :tracks, :Artists, :FeaturedArtists, :Genres, :SubGenres
    references    :imagefrontcover
  end

  # The API exposes two methpds for Releases.
  # FindByUPC is nothing more than a load using the UPC code as the ID attribute
end