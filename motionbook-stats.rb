#!/usr/bin/ruby 
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
		@deviation_url = url
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
ARGV[0] ? @starting_url = ARGV[0] : @starting_url = 'http://www.deviantart.com/motionbooks/?order=9'

# Set up mechanize agent.
@agent = Mechanize.new

# List that will contain all the links to the deviations in the motionbooks category.
@deviation_link_list = []





# Method definitions


def find_deviation_links(base_url, offset = 0)

	url = base_url + "&offset=" + offset.to_s

	# puts "getting #{url}. Press enter to continue..."

	# STDIN.gets

	page = @agent.get(url)

	t_links = false

	# puts "URL retrieved, t_links is currently #{t_links.to_s}."

	# puts "Press enter to continue..."

	# STDIN.gets

	page.links.each do |link|
		if link.dom_class == "t"

			# puts "t_link found: #{link}"
			# puts "Press enter to add to list and continue..."
			# STDIN.gets
			@deviation_link_list << link.href

			t_links = true
		end
	end

	if t_links == true
		
		# puts "t_links is true, restarting method with these params:"

		offset += 24

		# puts "base_url: #{base_url}, offset: #{offset}"

		# puts "Press enter to continue..."

		# # STDIN.gets

		find_deviation_links(base_url, offset)
		
	end

	
end


find_deviation_links(@starting_url)

puts @deviation_link_list






















