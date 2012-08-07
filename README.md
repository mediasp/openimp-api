# OpenIMP API Client

Client for communicating with OpenIMP APIs, such as that used by Consolidated Independent.

## Hello, World

    require 'ci-api'

    client = CI::Client.new('http://api.cissme.com/media/v1', {
      :username => 'mediaman',  :password => 'secretzzz'})

    release_by_uri = client.get('/release/upc/012345678')
    puts release_by_uri.inspect

    release_repo = CI::Repository::Release.new(client)
    release_by_find = release_repo.find(:upc => '012345678')
    puts release_by_find.inspect

