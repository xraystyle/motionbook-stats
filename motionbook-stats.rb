#!/usr/bin/ruby -w
system 'clear'

# Check that Mechanize is installed. If not, bail.
if `gem list | grep mechanize` == ""
	puts "The 'Mechanize' Rubygem is not currently installed on your system."
	puts "Install it from the command line with this command:\n\nsudo gem install mechanize\n\n"
	exit 1
end

# Model a Motionbook. Name, URL, stats, etc.
class Motionbook

# Class methods/variables ------

	@@motionbooks = []


	def self.all

		@@motionbooks
	
	end
# --------------------------------

# Instance methods/variables -------

	attr_reader :name, :url, :author, :views, :favs, :comments


	def initialize(name, url, author, views, favs, comments)

		@@motionbooks << self

		@name = name
		@url = url
		@author = author
		@views = views
		@favs = favs
		@comments = comments
		
	end

# ----------------------------------

end


# Useful variables/things that need to be set up.
require 'mechanize'

# What URL are we using? Default to motionbooks, have ability to pull in a 
# param for later functionality if necessary.
ARGV[0] ? @url = ARGV[0] : @url = 'http://www.deviantart.com/motionbooks/?order=9'

# Set up mechanize agent.
@agent = Mechanize.new

# List that will contain all the links to the deviations in the motionbooks category.
@deviation_link_list = []





# Method definitions


def find_deviation_links(url)

	page = @agent.get(url)

	page.links.each do |link|
		if link.dom_class == "t"
			# do something with the links.
			# add offset param, get more "t" links.
			# if no "t" links, bail.
		end
	end

	
end


























