module Enumerable #:nodoc:
  def map_to_hash container = {}
    inject(container) { |hash, item| hash.merge!(yield(item) || {}) }
  end

  def cartesian other
    inject([]) { |array, x| array << other.collect { |y| [x, y]} }
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