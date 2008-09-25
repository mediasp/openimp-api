module Enumerable
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
  
  def map_with_index
    result = []
    each_with_index {|x, i| result << yield(x, i)}
    result
  end
end