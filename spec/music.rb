#!/usr/bin/ruby -rrubygems
require "dm-core"
require '../lib/freebase_adapter'

DataMapper.setup(:default, :adapter => 'freebase')

class Artist
  include DataMapper::Resource

  storage_names[:freebase_repo] = '/music/artist'

  property :id, String, :key => true
  property :guid, String
  property :name, String
#  property :genre, String
#  property :label, String

  has n, :albums, :incoming_prop => '/music/artist/album'
end

class Album
  include DataMapper::Resource

  storage_names[:freebase_repo] = '/music/album'

  property :id, String, :key => true
  property :name, String
#  property :track, String
  property :release_date, Date

  has 1, :artist, :incoming_prop => '/music/album/artist'
end

begin
p artist = Artist.get('/en/apparat')
p artist.albums.collect(&:name)

p album = Album.get('/en/koax')
p album.artist if album

p albums = Album.all(:name => "Balance", :order => :release_date.asc)
p dates = albums.collect(&:release_date).compact
end

