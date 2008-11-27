require File.dirname(__FILE__) + '/test_common.rb'
class TestAsset < Test::Unit::TestCase
  include TestCommon
=begin
  def test_list_encodings
    assert_nil CI::Metadata::Encoding.encodings
    CI::Metadata::Encoding.synchronize
    assert_not_nil CI::Metadata::Encoding.encodings
    encoding = CI::Metadata::Encoding.new(:id => 'wma_192')
    assert_instance_of CI::Metadata::Encoding, encoding
    assert_equal encoding.name, 'wma_192'
  end
=end
end