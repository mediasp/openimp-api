module Enumerable #:nodoc:
  def map_to_hash
    inject({}) { |hash, item| hash.merge!(yield(item) || {}) }
  end

  def cartesian other
    inject([]) { |array, x| array << other.collect { |y| [x, y]} }
  end

=begin
  def map_to_hash(hash = {}) # or you could give eg a HashWithIndifferentAccess
    each do |x|
      key, value = yield x
      hash[key] = value
    end
    hash
  end

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