module CI
  class Error < Exception
    def self.json_create properties
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
 
    class_inheritable_accessor  :api_base_url, :api_class_name

    # Creates a canonical URL for the specified server-side object.
    def self.url id, *actions
      MediaFileServer.resolve self.api_base_url, id, actions.join("/")
    end

    def self.base_url url
      @api_base_url = url
    end

    # A +meta programming helper method+ which converts an MFS attribute into more manageable forms.
    def self.with_api_attributes *attributes
      Array.new(attributes).each do |api_attribute|
        yield api_attribute.to_method_name, api_attribute.to_sym
      end
    end

    # Not all MFS classes use +Id+ as their primary key, therefore we allow the primary key to be explicitly
    # named whilst still keeping the notion of an id
    def self.primary_key attribute
      with_api_attributes(attribute) do |ruby_method, api_key|
        define_method(:primary_key) { api_key }
        [:id, ruby_method].each do |accessor|
          define_method(accessor) { @parameters[api_key] }
          define_method("#{accessor}=") { |value| @parameters[api_key] = value }
        end
      end
    end

    # Defines an MFS attribute present on the current class and creates accessor methods for manupulating it.
    def self.attributes *attributes #:nodoc:
      with_api_attributes(*attributes) do |ruby_method, api_key|
        define_method(ruby_method) do
          # For attributes which expose only a representation we support lazy loading
          @parameters[api_key] = Asset.new(@parameters[api_key]) if @parameters[api_key]["__REPRESENTATION__"] rescue false
          @parameters[api_key]
        end
        define_method("#{ruby_method}=") { |value| @parameters[api_key] = value }
      end
    end

    # Defines an MFS attribute as representing a collection of one or more server-side objects and creates
    # accessor methods for manipulating it.
    def self.collections *attributes
      with_api_attributes(*attributes) do |ruby_method, api_key|
        define_method(ruby_method) { @parameters[api_key] || [] }
        define_method("#{ruby_method}=") do |values|
          @parameters[api_key] = values.map { |v| v.respond_to?(:has_key?) ? Asset.create(v) : v }
        end
      end
    end

    # We use a custom constructor to automatically load the correct object from the
    # CI MFS system if the parameters to +new+ include a +primary key+.
    def self.new parameters={}, *args
      asset = allocate
      case
      when id = parameters[asset.primary_key] || parameters[:id]
        asset = MediaFileServer.get(url(id))
      when representation = parameters['__REPRESENTATION__']
        asset = MediaFileServer.get(representation)
      else
        asset.send :initialize, parameters, *args
      end
      asset
    end

    # Create an instance of this class from a JSON object.
    def self.json_create properties
      asset = allocate
      asset.send :initialize, properties
      asset
    end

    primary_key   :Id
    attributes    :__REPRESENTATION__

    def initialize parameters = {}
      @parameters = {}
      parameters.delete_if { |k, v| k == '__CLASS__' }.each { |k, v| self.send("#{k.to_method_name}=", v) rescue nil }
    end

    # Calculate a URL relative to the current server object.
    def url action = nil
      self.class.url id, action
    end

    def to_json *a
      self.parameters.inject({'__CLASS__' => self.class.name.sub(/CI::/i, 'MFS::')}) { |h, (k, v)|
        h[k] = case v
        when true then 1
        when false then 0
        else v.to_json(*a)
        end
      }.to_json(*a)
    end

    [:get, :get_octet_stream, :head, :delete].each do |m|
      class_eval <<-METHOD
        def #{m} action = nil
          MediaFileServer.#{m} url(action)
        end
      METHOD
    end

    def post properties, action = nil, headers = {}
      MediaFileServer.post url(action), properties, headers
    end

    def multipart_post
      MediaFileServer.multipart_post(url()) { |url| yield url }
    end

    def put content_type, data
      MediaFileServer.put url(), content_type, data
    end

  protected
    def == asset
      parameters == asset.parameters
    end

    def replace_with! asset
      @parameters = asset.parameters
      self
    end

    def parameters
      @parameters.clone
    end
  end
  
  
  module Metadata
    # An +Encoding+ describes the audio codec associated with a server-side audio file.
    class Encoding < Asset
      primary_key   :Name
      base_url      :encoding
      attributes    :Codec, :Family, :PreviewLength, :Channels, :Bitrate, :Description
      @@encodings = nil

      def self.synchronize
        @@encodings = MediaFileServer.get(url nil)
      end

      def self.encodings
        @@encodings.dup rescue nil
      end
=begin
      # We use a custom constructor to automatically load the correct object from the
      # CI MFS system if the parameters to +new+ include a +name+.
      def self.new parameters={}, *args
        super parameters.merge(:Id => parameters[:Name] || parameters[:name], :Name => nil, :name => nil), *args
      end
=end
    end
  end

  # A +ContextualMethod+ is a method call avaiable on a server-side object.
  class ContextualMethod < Asset
    primary_key   :Name
  end
end