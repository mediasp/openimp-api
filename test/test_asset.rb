require File.dirname(__FILE__) + '/test_common.rb'
class TestAsset < Test::Unit::TestCase
  include TestCommon

  def test_list_encodings
    assert_nil CI::Metadata::Encoding.encodings
    CI::Metadata::Encoding.synchronize
    assert_not_nil CI::Metadata::Encoding.encodings
    encoding = CI::Metadata::Encoding.new(:id => 'wma_192')
    assert_instance_of CI::Metadata::Encoding, encoding
    assert_equal encoding.name, 'wma_192'
  end
  
  def test_equality_and_lack_thereof
    asset = CI::Metadata::Release.new(:id => TEST_UPC)
    asset2 = CI::Metadata::Release.new(:id => TEST_UPC)
    assert_equal asset, asset2
    assert_equal asset, asset
    assert_not_equal asset, 1234
    assert_not_equal asset, CI::Metadata::Release.new
    assert_not_equal CI::Metadata::Release.new, CI::Metadata::Release.new
    assert_equal 1, [asset, asset2].uniq.length
    assert_equal 1, {asset => 1}[asset2]
  end
end