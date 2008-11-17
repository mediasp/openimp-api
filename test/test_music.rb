require File.dirname(__FILE__) + '/test_common.rb'
class TestMusic < Test::Unit::TestCase
  include TestCommon
  
  def test_get_release
    r = CI::Release.find(TEST_UPC)
  end
end