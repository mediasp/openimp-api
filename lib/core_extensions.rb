module Enumerable #:nodoc:
  def map_to_hash container = {}
    inject(container) { |hash, item| hash.merge!(yield(item) || {}) }
  end

  def cartesian other
    inject([]) { |array, x| array << other.collect { |y| [x, y] } }
  end

=begin
  def cartesian(other)
    res = []
    each { |x| other.each { |y| res << [x, y] } }  
    return res
  end
=end

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

class SymmetricTranslationTable
  def initialize right, left
    @right, @left = {}, {}
    c = class << self; self; end
    c.send :define_method, :"define_#{right}_term", lambda { |name, value|
      @right[name] = value
      @left[value] = name
      }
    c.send :define_method, :"define_#{left}_term", lambda { |name, value|
      @left[name] = value
      @right[value] = name
      }
    # The following adds a bias in favour of right-hand definitions.
    c.send :define_method, :"[]", lambda { |name|
      @right[name] || @left[name]
      }
  end
end

class String
  def to_method_name
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').gsub(/([a-z\d])([A-Z])/,'\1_\2').tr("-", "_").downcase
  end
end