require 'test/unit'
require 'open-uri'
require File.dirname(__FILE__) + '/../lib/ci'

module TestCommon  
  TEST_ASSET_FILE = "#{File.dirname(__FILE__)}/test_assets/test_file.txt"
  TEST_IMAGE_FILE = "#{File.dirname(__FILE__)}/test_assets/test_image.jpg"
  
  def setup
    unless CI.username
      print "\nUsername: "
      CI.username = gets.chomp
    end
    unless CI.password
      print "\nPassword: "
      CI.password = gets.chomp
      print "\n"
    end
  end
  
  
  def test_truth
    assert true
  end
  
end