require 'test/unit'
require 'open-uri'
require File.dirname(__FILE__) + '/../lib/ci'

module TestCommon
  TEST_TEXT_FILE = "#{File.dirname(__FILE__)}/test_assets/test_file.txt"
  TEST_IMAGE_FILE = "#{File.dirname(__FILE__)}/test_assets/test_image.jpg"
  TEST_UPC = "634904018320"

  class << self
    attr_accessor :username, :password, :options
  end
  @username = 'playlouderapitest@ci-support.com'
  @password = nil
  @options = {}

  def setup
    unless TestCommon.username
      print "\nUsername: "
      TestCommon.username = gets.chomp
    end
    unless TestCommon.password
      file = File.dirname(__FILE__)+'/.password'
      TestCommon.password = if File.exist?(file)
        File.read(file)
      else
        print "\nPassword: "
        gets
      end.chomp
    end
    CI::MediaFileServer.configure(TestCommon.username, TestCommon.password, TestCommon.options)
  end

  def test_truth
    assert true
  end
end
