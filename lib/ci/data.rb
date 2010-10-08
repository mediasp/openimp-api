module CI
  module Data
    module ReleaseBatch
      def self.included(klass)
        klass.send :attributes, :Id, :name, :OrganisationName
      end

      # TODO: would be nice to have support for eg
      #   collection :releases_completed, :class => 'CI::Metadata::Release'
      # for situations where only __REPRESENTATION__ but not __CLASS__ is included.
      #
      # But, the code doesn't currently know how to infer values for the identifying
      # attributes (UPC in this case) from the URI, only the other way round.

      def releases_completed; @parameters[:releases_completed] || []; end
      def releases_completed=(values)
        @parameters[:releases_completed] = (values || []).map do |v|
          v.is_a?(Hash) ? Metadata::Release.new(:UPC => v["__REPRESENTATION__"][/(\d+)$/]) : v
        end
      end

      def releases_incomplete; @parameters[:releases_incomplete] || []; end
      def releases_incomplete=(values)
        @parameters[:releases_incomplete] = (values || []).map do |v|
          v.is_a?(Hash) ? Metadata::Release.new(:UPC => v["__REPRESENTATION__"][/(\d+)$/]) : v
        end
      end
    end

    class ImportRequest < Asset
      include ReleaseBatch
      attributes :Status
      attributes :OrganisationDPID, :OrganisationId

      def self.path_components(instance=nil)
        instance ? ['import', instance.id] : ['import']
      end
    end

    class Delivery < Asset
      include ReleaseBatch
      attributes :status

      include ReleaseBatch

      def self.path_components(instance=nil)
        instance ? ['delivery', instance.id] : ['delivery', 'to_me']
      end
    end

    class Offer < Asset
      attributes :UseType
      collections :Terms

      class Terms < Asset
        attributes :PreOrderReleaseDate, :Began, :Ended, :PriceRangeType
        collections :Countries
      end
    end

  end
end
