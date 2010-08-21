#=begin
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'music_domain'

#=begin
describe 'FreebaseAdapter', 'for music domain' do

  it "should fetch one-to-many associations on demand" do
    artist = Artist.get('/en/apparat')
    artist.albums
    artist.albums.size.should > 0
    titles = artist.albums.collect(&:name)
    ["Silizium EP", "Walls"].each do |title|
      titles.should include(title)
    end
  end

  it "should sort the result ascending" do
    albums = Album.all(:name => "Balance", :order => :release_date.asc)
    dates = albums.collect(&:release_date).collect { |date| d = date.to_s; d if d.size > 0}.compact
    dates.should == dates.sort
  end

  it "should sort the result descending" do
    albums = Album.all(:name => "Balance", :order => [:release_date.desc])
    dates = albums.collect(&:release_date).collect { |date| d = date.to_s; d if d.size > 0}.compact
    dates.should == dates.sort.reverse
  end

  it "should work with inclusion (in) queries" do
    results = Album.all(:name => ["Berlin Calling", "Balance 005: James Holden"])
    results.size.should == 2
    results[0].name.should == "Balance 005: James Holden"
    results[1].name.should == "Berlin Calling"
  end

  it "should work with like (regexp match) queries" do
    results = Album.all(:name.like => "Balance 00*")
    results.size.should > 0
    titles = results.collect(&:name)
    titles.each {|title| title.should =~ /^Balance 00.*$/}
  end
end
#=end
