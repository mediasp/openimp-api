module CI
  module Metadata
    class Recording < Asset
      primary_key   :ISRC
      base_url      :"recording/isrc"
      attributes    :Duration, :LabelName, :MainArtist
      collections   :Producers, :Mixers, :Composers, :Lyricists, :FeaturedArtists, :Artists, :tracks, :files

      def initialize parameters = {}
        super
      end
    end

    #TODO add methods to get encodings etc.
  end
end