module CI
  module Data

    class ImportRequest < Asset
      attributes :Id, :name, :OrganisationName
      attributes :releases_completed, :releases_incomplete, :type => :release_array
      attributes :Status
      attributes :OrganisationDPID, :OrganisationId

      def self.path_components(instance=nil)
        instance ? ['import', instance.id] : ['import']
      end
    end

    class Delivery < Asset
      attributes :Id, :name, :OrganisationName
      attributes :releases_completed, :releases_incomplete, :type => :release_array
      attributes :status

      def self.path_components(instance=nil)
        instance ? ['delivery', instance.id] : ['delivery', 'to_me']
      end
    end

    class Offer < Asset
      attributes :UseType
      collections :Terms

      class Terms < Asset
        attributes :Began, :Ended, :PreOrderReleaseDate, :type => :date
        attributes :Price
        collections :Countries
      end
    end

  end
end
