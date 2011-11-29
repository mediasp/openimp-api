require 'test/unit'
require 'yaml'

require 'ci'

begin
  TEST_CONFIG = YAML.load_file("#{File.dirname(__FILE__)}/config.yml")
rescue
  puts "Couldn't load test config in test/config.yml. Please make one from test/config.template.yml"
  exit 1
end

TEST_TEXT_FILE = "#{File.dirname(__FILE__)}/test_assets/test_file.txt"
TEST_IMAGE_FILE = "#{File.dirname(__FILE__)}/test_assets/test_image.jpg"
TEST_UPC = TEST_CONFIG[:test_upc]
TEST_ORGANISATION_ID = TEST_CONFIG[:test_organisation_id]

CI::MediaFileServer.configure(TEST_CONFIG[:username], TEST_CONFIG[:password], TEST_CONFIG)
