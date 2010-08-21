require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'film_domain'

#=begin
describe "FreebaseAdapter", "for film domain" do

  before do
    @film = Film.get('/en/the_certified_copy')
  end

  it "should fetch the a topic by id" do
    @film.name.should == "Certified Copy"
  end

  it "should fetch an assocation for the topic" do
    @film.genre.should_not be_empty
  end

  it "should fetch attributes of the associated topic" do
    @film.director[0].name.should  == "Abbas Kiarostami"
  end

  it "should filter associated topics using like" do
    @film.producer(:name.like => '%Karmitz').each { |producer|
      producer.name.should include('Karmitz')
    }
  end

  it "should filter associated topics using regexes" do
    pending("get =~ regex to work") do
      @film.producer(:name.like =~ /.*Karmitz$/).each { |producer|
        producer.name.should include('Karmitz')
      }
    end
  end

  it "should filter associated topics using gt" do
    @film.film_cuts(:runtime.gt => 10).should_not be_empty
    @film.film_cuts(:runtime.gt => 1000).should be_empty
  end

  it "should get runtime from the film" do
    @film.runtime.should == 106
  end

  it "should get a pluralized assocation" do
    @film.film_locations.should_not be_empty
  end

  it "should get an assocation through another association" do
    @film.actors.detect { |actor| actor.name == 'Juliette Binoche' }.should_not be_nil
  end

  it "should have webpages" do
    @film.webpages.should_not be_empty
  end

  it "should have a miff webpage" do
    @film.miff_webpage.should_not be_empty
  end

  it "should fetch film festival events" do
    @film.film_festival_events.collect(&:name).should include('2010 Melbourne International Film Festival')
  end

end
#=end

describe "FreebaseAdapter", "for an actor in film domain" do

  before do
    @actor = Actor.get('/en/juliette_binoche')
  end

  it "should fetch flims for this actor" do
    @actor.films.detect { |film| film.name == 'Certified Copy' }.should_not be_nil
  end

end


describe "FreebaseAdapter", "for collections in film domain" do

  it "should work with collections" do
    Film.all(:name.like => 'Certified').collect(&:film_cuts).flatten.collect(&:type_of_film_cut).first.should == 'Theatrical Release'
  end

  it "should work with performances" do
    performance = Performance.get('/m/02vc4kk')
    performance.character.should == 'Elle'
    performance.actor.name.should == 'Juliette Binoche'
    performance.film.name.should == 'Certified Copy'
  end

end

describe "FreebaseAdapter", "for film festival in film domain" do

  before do
    @miff2010 = FilmFestivalEvent.first(:name => '2010 Melbourne International Film Festival')
  end

  it "should retrieve films for a festival" do
    @miff2010.films.should_not be_empty
  end

  it "should find films based on initial_release_date" do
    @miff2010.films(:initial_release_date => "2008").each { |film|
      film.initial_release_date.should == '2008'
    }
  end

  it "should find films based on genre" do
    @miff2010.films(:initial_release_date => "2008", :genre => Genre.first(:name => 'Drama')).each { |film|
      film.initial_release_date.should == '2008' and film.genre.first.name.should == 'Drama'
    }
  end

  it "should find and order films based on multiple conditions" do
    prev_release_date = '2099'
    @miff2010.films(:language => Language.first(:name => 'Polish Language'), :order => [:initial_release_date.desc]).each { |film|
      film.to_s.should_not be_empty
      film.language.detect { |lang| lang.name == 'Polish Language' }.name.should == 'Polish Language'
      film.initial_release_date.should <= prev_release_date 
      prev_release_date == film.initial_release_date
    }
  end

  it "should find fields based on a set of conditions" do
    @miff2010.films(:language => [Language.first(:name => 'Italian Language'), Language.first(:name => 'Spanish Language')]).each { |film|
      l = film.language.detect { |lang| (lang.name == 'Italian Language') or (lang.name == 'Spanish Language') }.name
      ['Italian Language',  'Spanish Language'].should include(l)
    }
  end

  it "should join queries together" do
    hebrew_films = @miff2010.films(:language => Language.first(:name => 'Hebrew Language'))
    arabic_films = @miff2010.films(:language => Language.first(:name => 'Arabic Language'))
    hebrew_and_arabic_films = hebrew_films & arabic_films
    #langs = hebrew_and_arabic_films.collect { |f| f.language.collect(&:name) }  # XXX why doesn't this work?
    langs = hebrew_and_arabic_films.collect { |f| f }.collect { |f2| f2.language.collect(&:name) }.flatten
    langs.should include('Hebrew Language')
    langs.should include('Arabic Language')
  end

end

