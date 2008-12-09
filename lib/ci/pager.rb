module CI
  # CI::Pager is a container object for paged result sets returned from certain CI API methods.
  # It contains an array of URIs for the pages of the result set; each of these URIs, when loaded,
  # should contain an array of result objects.
  # We wrap this behaviour here in a pretty simple fashion, exposing Enumerable and some Array methods.
  class Pager
    class << self
      alias :json_create :new
    end

    def initialize json_data
      @pages = json_data['Pages']
    end

    include Enumerable

    def each
      @pages.length.times {|n| yield self[n]}
    end

    def [] n
      path = @pages[n]
      path_components = path.sub!(/^\//,'').split('/')
      MediaFileServer.get(path_components)
    end
    alias :page :[]

    def length
      @pages.length
    end
  end
end