module CI
  module Metadata
    class Release < Asset
      #TODO code to convert ISO Durations and dates / times to ruby objects.
      primary_key   :UPC
      base_url      :"release/upc"
      attributes    :LabelName, :CatalogNumber, :ReleaseType, :ParentalWarningType, :PriceRangeType
      attributes    :ReferenceTitle, :SubTitle, :Duration
      attributes    :MainArtist, :DisplayArtist
      attributes    :PLineYear, :PLineText, :CLineYear, :CLineText, :imagefrontcover
      attributes    :TrackCount
      collections   :tracks, :Artists, :FeaturedArtists, :Genres, :SubGenres

      def self.list
        MediaFileServer.get "/release/list"
      end
    end

    # The API exposes two methpds for Releases.
    # FindByUPC is nothing more than a load using the UPC code as the ID attribute
  end
end