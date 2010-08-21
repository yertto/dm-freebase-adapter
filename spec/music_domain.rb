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
