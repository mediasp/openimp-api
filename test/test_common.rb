require 'test/unit'
require 'open-uri'
require File.dirname(__FILE__) + '/../lib/ci'

module TestCommon  
  TEST_ASSET_FILE = "#{File.dirname(__FILE__)}/test_assets/test_file.txt"
  TEST_IMAGE_FILE = "#{File.dirname(__FILE__)}/test_assets/test_image.jpg"
  TEST_UPC = 634904120498
  
  def setup
    CI::MediaFileServer.protocol = :http
    CI::MediaFileServer.port = 80
    CI::MediaFileServer.host = 'api.stage'
    unless CI::MediaFileServer.username
      print "\nUsername: "
      CI::MediaFileServer.username = gets.chomp
    end
    unless CI::MediaFileServer.password
      print "\nPassword: "
      CI::MediaFileServer.password = gets.chomp
      print "\n"
    end
  end
  
  
  def test_truth
    assert true
  end
  
end