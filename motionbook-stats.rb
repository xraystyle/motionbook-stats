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

# Log into DA so mature deviations can be parsed.
def login(user = nil, pass = nil)

	# check for passed creds. If none, ask.
	username = user if user
	password = pass if pass

	unless user
		puts "\nEnter valid DA login creds.\n"

		print "User: "
		username = STDIN.gets.chomp
		print "Pass: "
		password = STDIN.gets.chomp
	end
	
	homepage = @agent.get('http://deviantart.com')

	login_form = homepage.form_with(dom_id: "form-login")

	login_form.field_with(dom_id: "login-username").value = username
	login_form.field_with(dom_id: "login-password").value = password

	login_form.submit


end

# Get all the links to deviations within the motionbooks category.
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
			# puts link.text
			# puts "Press enter to add to list and continue..."
			# STDIN.gets
			@deviation_link_list << link

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

# pull the stats from the deviation pages and put together Motionbook instances
# with the relevant data.
def get_deviation_stats

	# Handle potential errors.
	unless @deviation_link_list.any?
		puts "No deviations in list to get stats from, exiting."
		exit 1		
	end

	spinner = ['|', '/', '-', "\\"]
	spinner_position = 0 		
	
	@deviation_link_list.each do |link|

		begin

			system 'clear'

			print "Working... #{spinner[spinner_position]}\n\n"        
			# empty array to hold the data we want from the 'dd' tags.
			dd_values = []

			deviation_page = @agent.get(link.href)

			author = deviation_page.link_with(dom_class: "u beta username").text

			# find the div that contains the deviation stats.
			stats_div = deviation_page.search('.dev-metainfo-stats')
			# Find all the descriptions within the div. This will be the relevant info.
			dds = stats_div.search('dd')

			# Shit the values of the dd tags into an array for cleanup.
			dds.each do |d|
		    	dd_values << d.content.chomp.strip
		 	end

		 	# let's get some nicely formatted data.
		 	views = dd_values[0].match(/([0-9,]+) ?\(?/)[1].gsub(/,/, "")

		 	favs = dd_values[1].match(/([0-9,]+) ?\(?/)[1].gsub(/,/, "")

		 	comments = dd_values[2].to_s.gsub(/,/, "")

		 	# Make a new Motionbook instance with our lovely data.
		 	# Template: Motionbook.new(name, url, author, views, favs, comments)

		 	book = Motionbook.new(link.text, link.href, author, views, favs, comments)

		 	if spinner_position == 3
		 		spinner_position = 0
		 	else
		 		spinner_position += 1
		 	end

	 	rescue Exception => e
	 		puts "Something went sideways..."
	 		puts e
	 		puts "Press enter to continue..."
	 		STDIN.gets
		end


	end



end



puts "Motionbooks Stats Reporter"

login

puts "\nFinding all deviations within the category...\n"

find_deviation_links(@starting_url)

puts "Found #{@deviation_link_list.count} deviations."
puts "Begining Stats parsing..."

sleep 3

get_deviation_stats

puts "Preparing detailed deviation stats..."

sleep 3

system 'clear'

print "Book Name".ljust(50)
print "Book Author".ljust(25)
print "Views".ljust(10)
print "Favs".ljust(10)
print "Comments".ljust(10)
puts
puts

Motionbook.all.each do |book|

	print book.name.ljust(50)
	print book.author.ljust(25)
	print book.views.ljust(10)
	print book.favs.ljust(10)
	print book.comments.ljust(10)
	puts
	puts
end


























