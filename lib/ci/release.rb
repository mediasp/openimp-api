module CI
  module Metadata
    class Release < Asset
      attributes :UPC, :LabelName, :CatalogNumber, :ReleaseType, :ParentalWarningType, :PriceRangeType
      attributes :ReferenceTitle, :SubTitle, :Duration
      attributes :MainArtist, :DisplayArtist
      attributes :PLineYear, :PLineText, :CLineYear, :CLineText, :imagefrontcover
      attributes :TrackCount, :external_identifiers
      attributes :ReleaseDate, :type => :date

      # ArtistAppearance
      attributes :inferred_artist_identifiers
      attributes :provided_artist_identifiers

      # this is a bit of a pseudo attribute.
      # Releases do exist against an organisation, but this information is not
      # included in the api and it is not simple to infer this information as
      # the canonical uri for the release doesn't include the organisation id
      # (yet)
      # This is here solely so that you can call
      # Release.find(:organisation_id => 'asdfasdf', :upc => '123123')
      attr_accessor :organisation_id

      collections :tracks, :Artists, :FeaturedArtists, :Genres, :SubGenres, :offers

      # "GRiD" doesn't auto-camel-case very nicely
      def grid; @parameters['GRiD']; end
      def grid=(grid); @parameters['GRiD'] = grid; end

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
  end
end
