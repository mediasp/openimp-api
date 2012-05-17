module CI::Repository
  # helpful base class for using CI::Client to talk to a CI API
  class Base

    attr_reader :client

    def initialize(client)
      @client = client
    end

    # should return the class (or something that responds to new) to return
    # a new blank instance of a model object
    def model_class
      raise NotImplementedError
    end

    # should return an array of the path components that represent the base
    # of this resource type, i.e ['release', 'track'] would be /release/track
    # if an instance is provided, it returns the path to that particular instance
    # of a resource
    def path_components(instance=nil)
      raise NotImplementedError
    end

    def path_for(*args)
      "/" + path_components(*args).join("/")
    end

    # Call to fetch an asset from the database. You need to specify the
    # attributes necessary to identify the object, as required by your
    # overriden version of repository.path_components to generate a URL path for
    # the object.
    def find(parameters)
      stub = model_class.new(parameters)
      path = path_for(stub)
      raise "Insufficient attributes were passed to CI::Asset.find to generate a URL" unless path

      @client.get(path)
    end

    def find_or_new(parameters)
      find(parameters) || new(parameters)
    end

    def reload(instance)
      @client.get(path_for(instance))
    end

  end
end
