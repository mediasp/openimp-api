module CI
  module Metadata
    class Release < Asset
      #TODO code to convert ISO Durations and dates / times to ruby objects.
      attributes    :UPC, :LabelName, :CatalogNumber, :ReleaseType, :ParentalWarningType, :PriceRangeType
      attributes    :ReferenceTitle, :SubTitle, :Duration
      attributes    :MainArtist, :DisplayArtist
      attributes    :PLineYear, :PLineText, :CLineYear, :CLineText, :imagefrontcover
      attributes    :TrackCount, :external_identifiers
      attributes :ReleaseDate, :type => :date

      collections   :tracks, :Artists, :FeaturedArtists, :Genres, :SubGenres, :offers

      def self.path_components(instance=nil)
        if instance
          ['release', 'upc', instance.upc] if instance.upc
        else
          ['release']
        end
      end

      module ParentalWarning
        EXPLICIT                = 'Explicit'
        NO_ADVICE_AVAILABLE     = 'NoAdviceAvailable'
        EXPLICIT_CONTENT_EDITED = 'ExplicitContentEdited'
        NOT_EXPLICIT            = 'NotExplicit'
      end

      # Returns true, false, or nil (don't know).
      # So you can check explicitly for nil, or just treat as boolean and presume not explicit when not known.
      def explicit?
        case parental_warning_type
        when ParentalWarning::EXPLICIT then true
        when ParentalWarning::EXPLICIT_CONTENT_EDITED, ParentalWarning::NOT_EXPLICIT then false
        else nil # we don't know
        end
      end
    end

    # The API exposes two methpds for Releases.
    # FindByUPC is nothing more than a load using the UPC code as the ID attribute
  end
end
