module CI
  module Data

    class ReleaseBatch < Asset
      attributes :Id, :name, :OrganisationName, :OrganisationDPID, :OrganisationId
      attributes :releases_completed, :releases_incomplete, :type => :release_array
      attributes :Status
    end

    class ImportRequest < ReleaseBatch ; end
    class Delivery      < ReleaseBatch ; end

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
