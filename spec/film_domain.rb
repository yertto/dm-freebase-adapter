class Genre
  include DataMapper::Resource

  storage_names[:freebase_repo] = '/film/film_genre'

  property :id    , String , :key => true
  property :name  , String

  has n, :films , :through => Resource , :incoming_prop => '/film/film_genre/films_in_this_genre'
end

class Director
  include DataMapper::Resource

  storage_names[:freebase_repo] = '/film/director'

  property :id    , String , :key => true
  property :name  , String

  has n, :films , :through => Resource
end

class Writer
  include DataMapper::Resource

  storage_names[:freebase_repo] = '/film/writer'

  property :id    , String , :key => true
  property :name  , String

  has n, :films , :through => Resource
end

class Producer
  include DataMapper::Resource

  storage_names[:freebase_repo] = '/film/producer'

  property :id    , String , :key => true
  property :name  , String

  has n, :films , :through => Resource
end

class FilmLocation
  include DataMapper::Resource

  storage_names[:freebase_repo] = '/film/film_locations'

  property :id    , String , :key => true
  property :name  , String

  has n, :films , :through => Resource
end

class Country
  include DataMapper::Resource

  storage_names[:freebase_repo] = '/location/country'

  property :id    , String , :key => true
  property :name  , String

  has n, :films , :through => Resource
end

class Language
  include DataMapper::Resource

  storage_names[:freebase_repo] = '/language/human_language'

  property :id    , String , :key => true
  property :name  , String

  has n, :films , :through => Resource
end

class Rating
  include DataMapper::Resource

  storage_names[:freebase_repo] = '/film/content_rating'

  property :id    , String , :key => true
  property :name  , String

  has n, :films , :through => Resource
end

class FilmCut
  include DataMapper::Resource

  storage_names[:freebase_repo] = '/film/film_cut'

  property :id               , String  , :key => true
  property :name             , String
  property :runtime          , Integer
  property :type_of_film_cut , String

  belongs_to :film
end

class Actor
  include DataMapper::Resource

  storage_names[:freebase_repo] = '/film/actor'

  property :id    , String , :key => true
  property :name  , String

  has n, :performances, :through => Resource, :incoming_prop => '/film/actor/film'

  def films
    performances.collect(&:film)
  end
end

class Performance
  include DataMapper::Resource

  storage_names[:freebase_repo] = '/film/performance'

  property :id        , String , :key => true
  property :character , String , :required => false

  has     1, :film  , :through => Resource , :incoming_prop => '/film/performance/film'
  has     1, :actor , :through => Resource , :incoming_prop => '/film/performance/actor'
end


class Resauce
  include DataMapper::Resource

  storage_names[:freebase_repo] = '/common/topic/webpage'

  property :id        , String , :key => true
  property :name      , String
end


class Webpage
  include DataMapper::Resource

  storage_names[:freebase_repo] = '/common/topic/webpage'

  property :id        , String , :key => true

  has     1, :resauce  , :through => Resource , :incoming_prop => '/common/webpage/resource'
end


class Film
  include DataMapper::Resource

  storage_names[:freebase_repo] = '/film/film'

  property :id                   , String , :key => true
  property :name                 , String
  property :initial_release_date , String

  has n, :film_cuts                                          , :incoming_prop => '/film/film/runtime'
  has n, :performances                , :through => Resource , :incoming_prop => '/film/film/starring'
  has n, :genre ,:via=>:genres        , :through => Resource , :incoming_prop => '/film/film/genre'
  has n, :director, :via=>:directors  , :through => Resource , :incoming_prop => '/film/film/directed_by'
  has n, :writer, :via=>:writers      , :through => Resource , :incoming_prop => '/film/film/written_by'
  has n, :producer, :via=>:producers  , :through => Resource , :incoming_prop => '/film/film/produced_by'
  has n, :country, :via=>:countries   , :through => Resource , :incoming_prop => '/film/film/country'
  has n, :language, :via=>:langauges  , :through => Resource , :incoming_prop => '/film/film/language'
  has n, :rating, :via=>:ratings      , :through => Resource , :incoming_prop => '/film/film/rating'
  has n, :film_locations              , :through => Resource , :incoming_prop => '/film/film/featured_film_locations'
  has n, :film_festival_events        , :through => Resource , :incoming_prop => '/film/film/film_festivals'
                                      
  has n, :webpages                    , :through => Resource , :incoming_prop => '/common/topic/webpage'
                                      
  #has n, :actors                      , :through => :performances   # XXX this requires a nasty hack in incoming_prop accessor to work

  def actors
    #@actors ||= performances.collect {|x| Performance.get(x.id).actor}
    @actors ||= performances.actor
  end
  
  def runtime
    film_cuts.first.runtime
  end

  def initial_release_year
    @initial_release_year ||= if initial_release_date.is_a? String
      initial_release_date[0..3]
    else
      initial_release_date.to_i
    end
  end

  def miff_webpage
    @miff_webpage ||= if r = webpages.collect(&:resauce).compact.detect { |r| r.name == "Melbourne International Film Festival"}
      encoded_url = r.id.split('/')[-1]
      encoded_url.scan(/[$][0-9A-F]{4}/).uniq.inject(encoded_url) { |z,y| z.gsub!(y, y[1..4].to_i(16).chr) }
    end
  end

  def miff_id
    @miff_id ||= if w = miff_webpage
      w.split('=')[-1].to_i
    end
  end

  def to_s
    "#{miff_id} \t" +
    "#{initial_release_year} #{name}" +
    "#{        rating.size > 0 ? (' ['+        rating.collect(&:name).join(', ')+']') : ''}" +
    "#{         genre.size > 0 ? (' ('+         genre.collect(&:name).join(', ')+')') : ''}" +
    "#{film_locations.size > 0 ? (' <'+film_locations.collect(&:name).join(', ')+'>') : ''}" +
    "#{       country.size > 0 ? (' ['+       country.collect(&:name).join(', ')+']') : ''}" +
    "#{      language.size > 0 ? (' ['+      language.collect(&:name).map {|x| x.sub(/ language/i, '')}.join(', ')+']') : ''}"
  end
end

class FilmFestivalEvent
  include DataMapper::Resource

  storage_names[:freebase_repo] = '/film/film_festival_event'

  property :id           , String   , :key => true
  property :name         , String
  property :festival     , String
  property :opening_date , DateTime
  property :closing_date , DateTime

  has n, :films , :through => Resource, :incoming_prop => '/film/film_festival_event/films'
end
