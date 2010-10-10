module CI
  class Error < Exception
    def self.json_create(properties)
      raise new(properties["errormessage"])
    end

    [:PermissionDenied, :NotImplemented, :Conflict, :BadParameters, :NotFound].each do |error|
      class_eval <<-CLASS
        class #{error} < Error
        end
      CLASS
    end
  end

  # The +Asset+ class defines the core features of server-side objects, including the ability to autoinstantiate them
  # from _JSON_ for transport across the network.
  class Asset
    # Simple implementation of a +class inheritable accessor+.
    def self.class_inheritable_accessor(*args)
      args.each do |arg|
        class_eval <<-METHODS
          def self.#{arg}
            @#{arg} ||= superclass.#{arg} unless self == CI::Asset
          end

          def self.#{arg}=(val)
            @#{arg}=val
          end
        METHODS
      end
    end

    # should return a list of path components for (if no instance given) the base URL for the object type, otherwise the base URL for the instance given.
    # You need to override this to specify the URL format for any asset subclass.
    def self.path_components(instance=nil)
      raise NotImplemented, "You need to override CI::Asset.path_components"
    end

    def self.list
      MediaFileServer.get(path_components + ['list'])
    end

    def self.make_ci_method_name(string)
      string.to_s.
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').tr("-", "_").
        downcase
    end

    # A +meta programming helper method+ which converts an MFS attribute into more manageable forms.
    def self.with_api_attributes(*attributes)
      Array.new(attributes).each do |api_attribute|
        yield(make_ci_method_name(api_attribute), api_attribute.to_s)
      end
    end

    # equality based on the path_components (the URL is necessarily a unique identifier for a resource within the API)
    def ==(other)
      super or (other.instance_of?(self.class) && path_components && path_components == other.path_components)
    end
    def hash; path_components.hash; end
    alias :eql? :==

    def self.attribute_types
      @attribute_types ||= (superclass.respond_to?(:attribute_types) ? superclass.attribute_types.dup : {})
    end

    # Defines an MFS attribute present on the current class and creates accessor methods for manupulating it.
    def self.attributes(*attributes) #:nodoc:
      options = attributes.last.is_a?(Hash) ? attributes.pop : {}
      type = options[:type]

      with_api_attributes(*attributes) do |ruby_method, api_key|
        attribute_types[api_key] = type
        define_method(ruby_method) do
          # For attributes which expose only a representation we support lazy loading
          result = @parameters[api_key]
          if result.is_a?(Hash) && (url = result["__REPRESENTATION__"])
            path_components = url.sub(/^\//,'').split('/')
            @parameters[api_key] = MediaFileServer.get(path_components)
          else
            result
          end
        end
        define_method("#{ruby_method}=") { |value| @parameters[api_key] = value }
      end
    end

    # Defines an MFS attribute as representing a collection of one or more server-side objects and creates
    # accessor methods for manipulating it.
    def self.collections(*attributes)
      with_api_attributes(*attributes) do |ruby_method, api_key|
        define_method(ruby_method) { @parameters[api_key] || [] }
        define_method("#{ruby_method}=") {|values| @parameters[api_key] = values}
      end
    end

    class << self
      # Instantiate from the Hash resulting from the JSON parse,
      #
      # (This will use the special __REPRESENTATION__ attribute returned by the API to cache the instance's 'path_components', which is something we need to do
      #  in the case where a __CLASS__ and a __REPRESENTATION__ are supplied but there aren't sufficient attributes supplied to generate the URL
      #  path for the object ourself.)
      def json_create(parameters)
        parameters.delete('__CLASS__')
        representation = parameters.delete('__REPRESENTATION__')
        path_components = representation && representation.sub(/^\//,'').split('/')

        ruby_params = {}
        parameters.each do |k, v|
          ruby_params[k] = case attribute_types[k]
          when :date
            Date.parse(v) if v && !v.empty?
          when :duration
            # http://en.wikipedia.org/wiki/ISO_8601#Durations  PT00H00M00S format
            # we expose this as an integer number of seconds
            v =~ /^PT(\d\d)H(\d\d)M(\d\d)S$/i and $1.to_i*3600 + $2.to_i*60 + $3.to_i
          when :release_array
            (v || []).map do |h|
              Metadata::Release.new(:upc => h["__REPRESENTATION__"][/(\d+)$/])
            end
          else
            v
          end
        end

        result = new
        result.instance_variable_set(:@parameters, ruby_params)
        result.instance_variable_set(:@path_components, path_components)
        result
      end

      # Call to fetch an asset from the database. You need to specify the attributes necessary to identify the object, as required by your
      # overriden version of CI::Asset.path_components to generate a URL path for the object.
      def find(parameters)
        stub = new(parameters)
        path = stub.path_components
        raise "Insufficient attributes were passed to CI::Asset.find to generate a URL" unless path
        MediaFileServer.get(path)
      end

      def find_or_new(parameters)
        find(parameters) || new(parameters)
      end
    end

    # this can be used to create a new instance of an asset from a user-supplied attribute hash.
    def initialize(parameters = {}, path_components = nil)
      @parameters = {}
      parameters.each {|k,v| send(:"#{k}=", v)}
    end

    # this returns an array of strings consisting of the path components for the canonical URL for this asset/resource.
    # as a convenience, you can pass additional path components as arguments and it'll tack them on the end.
    # note that objects are compared for identity by comparing these; also note that sometimes, the value of this method is obtained from the
    # original __REPRESENTATION__ we were passed for the object, whereas other times (eg in the case of a new object) it's generated from the
    # object's attributes.
    def path_components(*args)
      components = if defined?(@path_components)
        @path_components
      else
        @path_components = self.class.path_components(self) and @path_components.map! {|c| c.to_s} # we normalise this to a string representation for comparison purposes
      end
      components && components + args
    end

    def to_json(*a)
      result = {'__CLASS__' => self.class.name.sub(/CI::/i, 'MFS::')}
      parameters.each do |k,v|
        result[k] = case self.class.attribute_types[k]
        when :date
          v && v.to_s
        when :duration
          mins, secs = v.divmod(60)
          hours, mins = mins.divmod(60)
          sprintf("PT%02dH%02dM%02dS", hours, mins, secs)
        else
          v
        end
      end
      result.to_json(*a)
    end

    # in all these methods, MediaFileServer takes a list of path components, and handles generating the URL from these itself.
    # (this is because of the possible presence of extra path components which depend on the API endpoint URL - eg /v1/ )

    [:get, :get_octet_stream, :head, :delete].each do |m|
      class_eval <<-METHOD
        def #{m} action = nil
          MediaFileServer.#{m}(path_components(action))
        end
      METHOD
    end

    def post(properties, action = nil, headers = {})
      MediaFileServer.post(path_components(action), properties, headers)
    end

    def multipart_post
      MediaFileServer.multipart_post(path_components || self.class.path_components) {|url| yield url}
    end

    def put(content_type, data)
      MediaFileServer.put(path_components, content_type, data)
    end

    # returns a reloaded version of self, fetched from the URL given by its path_components
    def reload
      pc = path_components() or raise "Insufficient attributes were defined to generate a URL in order to reload"
      MediaFileServer.get(pc)
    end

    # state-modifying version of reload
    def reload!
      replace_with!(reload)
    end

  protected
    def replace_with! asset
      @parameters = asset.parameters
      @path_components = asset.path_components
      self
    end

    def parameters
      @parameters.clone
    end
  end


  module Metadata
    # An +Encoding+ describes the audio codec associated with a server-side audio file.
    class Encoding < Asset
      attributes    :Name, :Codec, :Family, :PreviewLength, :Channels, :Bitrate, :Description
      @@encodings = nil

      def self.path_components(instance=nil)
        if instance
          ['encoding', instance.name] if instance.name
        else
          ['encoding']
        end
      end

      def self.synchronize
        @@encodings = MediaFileServer.get(path_components)
      end

      def self.encodings
        @@encodings.dup rescue nil
      end
    end
  end

  # A +ContextualMethod+ is a method call avaiable on a server-side object.
  class ContextualMethod < Asset
  end
end
