class CI::AbstractResource
  
  
  #ROUGH PLAN:
  
  # define subclasses with following dsl-like methods
  # ci_properties :Foo, :BarBaz, :Etc
  # findable_by :Foo, [:BarBaz, :Gubbins], :Etc #maps to find_by_foo, find_by_bar_and_baz, find_by_etc
  # allowed_methods :put, :post, :get, :etc #enables finders and save methods accordingly.
  
  def self.ci_properties(*properties)
    properties = [properties] unless properties.is_a?(Array)
    properties.each do |property|
      method = CI.ci_property_to_method_name(property)
      self.define_method(method, lambda {
          self.params[method]
      })
      self.define_method(method + '=', lambda{ |value|
        self.params[method] = value
      }) unless method =~ /^\_\_/
    end
  end

  
  def self.uri_path
    ''
  end
  
  def initialize(params={})
    @params = HashWithIndifferentAccess.merge(params)
  end
  
      
  def self.find(prms)
    params = CI.find(self, prms) if self.class.allowed_methods.include?(:get) #
    return self.new(params) if params
  end
  
  def self.create(prms)
    instance = self.new(prms)
    instance.save
    return instance
  end
  
  def save
    CI.save(self) if self.class.allowed_methods.include?(:post)
  end
  
end