class CI::Request
  attr_reader :resource_class, :http_method, :url_pattern, :post_params, :callback, :multipart
  
  def initialize(resource_class, http_method, url_pattern=[], post_params={}, multipart=true, &callback)
    local_variables.each do |var|
      instance_variable_set("@#{var}".to_sym, eval(var))
    end
    #Instead of this guff:
    #@resource_class = resource_class
    #@http_method = http_method
    #@url_pattern = url_pattern
    #@post_params = post_params
    #@multipart = multipart
    #@callback = callback
  end
  
end