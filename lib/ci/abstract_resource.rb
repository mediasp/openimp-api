class CI::AbstractResource
    
  def self.ci_properties(*properties)
    properties = [properties] unless properties.is_a?(Array)
    properties.each do |property|
      method = CI.ci_property_to_method_name(property)
      self.define_method(method, lambda {
          self.params[property]
      })
      self.define_method(method + '=', lambda{ |value|
        self.params[property] = value
      })
    end
  end

  
  def self.uri_path
    ''
  end
  
  def initialize(params={})
    @params = params
  end
  
      
  def find(prms)
  end
  
  def create(prms)
  end
  
end