module Enumerable #:nodoc:
  def map_to_hash container = {}
    inject(container) { |hash, item| hash.merge!(yield(item) || {}) }
  end

  def cartesian other
    inject([]) { |array, x| array << other.collect { |y| [x, y] } }
  end

  def map_with_index
    result = []
    each_with_index {|x, i| result << yield(x, i)}
    result
  end
end

class Hash
  def to_query
    map { |k, v| "#{k}=#{v}" }.join('&')
  end
end

class String
  def to_method_name
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').gsub(/([a-z\d])([A-Z])/,'\1_\2').tr("-", "_").downcase
  end
end

class Symbol
  def to_method_name
    self.to_s.to_method_name
  end
end

module Kernel
  def with_aliased_namespace original, synonym, &block
    s = synonym.to_s.to_sym
    Object.send(:remove_const, s) if  old_binding = (Object.const_get(s) rescue nil)
    Object.const_set(s, original)
    result = yield
    Object.send(:remove_const, s)
    Object.const_set(s, old_binding) if old_binding
    result
  end
end