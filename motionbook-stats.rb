#!/usr/bin/ruby 
system 'clear'


# ----------------- Startup Boilerplate ------------------------

# Check that Mechanize is installed. If not, bail.
if `gem list | grep mechanize` == ""
	puts "The 'Mechanize' Rubygem is not currently installed on your system."
	puts "We can attempt to install it for you with the following command: 'sudo gem install mechanize'"
	puts "Note: if you're using a ruby environment manager such as RVM, you should install this manually without"
	puts "using 'sudo'. If you don't know what this means, it likely doesn't apply to you."
	print "Would you like to continue? (y/n) \n> "
	response = STDIN.gets.chomp.strip.downcase
	options = ["y", "n"]

	while !options.include? response
		puts "Try again. 'y' to continue or 'n' to abort. (y/n)?"
		print "> "
	end

	case response
	when 'y'
		begin
			output = `sudo gem install mechanize`
			puts output
			puts "It appears the 'Mechanize' gem installed successfully."
			puts "Continuing..."
			sleep 3
		rescue Exception => e
			puts "It appears 'Mechanize failed to install correctly. Verify your installation,\nor try again manually."
			puts "Error code:"
			puts e
			exit 1
		end
	when "n"
		puts "User aborted, exiting..."
		sleep 2
		exit 1
	end
end


# ----------------- End Startup Boilerplate ------------------------



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

	# Make a nice array for the CSV output.
	def make_array

		array = []
		# ["Name", "Author", "URL", "Views", "Favs", "Comments"]
		array << @name
		array << @author
		array << @deviation_url
		array << @views
		array << @favs
		array << @comments
		return array
		
	end

	# ----------------------------------

end


# Useful variables/things that need to be set up.
require 'mechanize'
require 'csv'
require 'open-uri'

# What URL are we using? Default to motionbooks, have ability to pull in a 
# param for later functionality if necessary.
ARGV[0] ? @starting_url = ARGV[0] : @starting_url = 'http://www.deviantart.com/motionbooks/?order=9'


# Method definitions

# Log into DA so we can get links to mature deviations.
# They don't show up in the list if you're logged out.
def login(user, pass, mechanize_agent)

	tries = 0
	begin	
		homepage = mechanize_agent.get('http://deviantart.com')

		login_form = homepage.form_with(dom_id: "form-login")

		login_form.field_with(dom_id: "login-username").value = user
		login_form.field_with(dom_id: "login-password").value = pass

		login_form.submit
	rescue
		puts "Login error. retrying..."
		tries += 1
		if tries < 3
			sleep (2 ** tries)
			retry
		else 
			puts "Tried three times, bailing."
		end
	end

end


# Get all the links to deviations within the motionbooks category.
def find_deviation_links(base_url, offset = 0)

	url = base_url + "&offset=" + offset.to_s

	page = @agent.get(url)

	t_links = false
	# We're looking for links with dom class 't'.
	# They're the links to the deviation pages, and also the deviation titles.
	page.links.each do |link|
		if link.dom_class == "t"
			# if we find any, add them to the list, and set t_links to true.
			# This starts the next recursive run of the method.
			@deviation_link_list << link
			t_links = true
		end
	end

	if t_links == true
		offset += 24
		find_deviation_links(base_url, offset)
		# if t_links is false here, it's because we didn't
		# find any on the page. We've reached the last page 
		# of links.
	end
end

#start a thread that will retrieve data for a motionbook deviation.
def start_thread(link)
	
	if Thread.list.count < 30

		t = Thread.new do
			retrieve_motionbook(link, @agent)
		end

		@threads << t

		return t

	else
		return false
	end

end



# retrieve the individual motionbook page, use the stats to make a 
# motionbook instance.
def retrieve_motionbook(link, mechanize_agent)
	tries = 0
	begin
		dd_values = []

		deviation_page = mechanize_agent.get(link.href)

 	rescue Exception => e
 		
 		puts "Error downloading book #{link.text}, retrying..."
 		if tries < 5
 			sleep (2 ** tries)
 			tries +=1
 			retry
 		else
 			puts "Tried three times, giving up."
 			@book_errors_list << link
 			return
 		end

	end

	begin
		# Process the URL.
		puts "Book #{link.text} retrieved, processing...\n\n"

		author = deviation_page.link_with(dom_class: %r{u.*username.*}).text

		# find the div that contains the deviation stats.
		stats_div = deviation_page.search('.dev-metainfo-stats')
		# Find all the descriptions within the div. This will be the relevant info.
		dds = stats_div.search('dd')

		# Put the values of the dd tags into an array for cleanup.
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

	 	puts "Book #{book.name} processed.\n\n"
	 rescue Exception => e
	 	puts "Processing error, #{e}"
	 	@book_errors_list << link
	 end

end



# ----------------------------------- Begin script -----------------------------------

# Set up mechanize agent.
@agent = Mechanize.new do |a|
	a.follow_meta_refresh = true
	a.keep_alive = false
	a.history.max_size = 10
end


# List that will contain all the links to the deviations in the motionbooks category.
@deviation_link_list = []
@book_errors_list = []

# List of all the running threads, so we can wait for them to finish.
@threads = []


puts "Motionbooks Stats Reporter"

puts "\nEnter valid DA login creds.\n"

print "User: "
@username = STDIN.gets.chomp
print "Pass: "
@password = STDIN.gets.chomp

login(@username, @password, @agent)

puts "\nFinding all deviations within the category...\n"

find_deviation_links(@starting_url)

puts "Found #{@deviation_link_list.count} deviations."
puts "Begining Stats parsing..."

sleep 3

# Handle potential errors.
unless @deviation_link_list.any?
	puts "No deviations in list to get stats from, exiting."
	exit 1		
end

# Spin off threads to process every motionbook link, 30 at a time.
loop = Thread.new do
	@deviation_link_list.each_with_index do |link, index|
		
		thread = start_thread(link)
		# If start_thread returns false, there's too many active threads. Retry til a slot opens up.
		redo if thread == false

	end
end


# Make sure the loop finishes.
loop.join
	
# Make sure all motionbook threads finish.
@threads.each { |t| t.join }



puts "Preparing detailed deviation stats..."

sleep 3

CSV.open(File.expand_path("~/Desktop/motionbook_stats.csv"), "wb") do |csv|
	# Template: Motionbook.new(name, url, author, views, favs, comments)

	csv << ["Name", "Author", "URL", "Views", "Favs", "Comments"]
	
	Motionbook.all.each do |book|

		csv << book.make_array

	end

end

puts "CSV file with all data has been saved to the desktop.\n\n"

if @book_errors_list.any?
	puts "There were errors processing the following books:\n"
	@book_errors_list.each do |book|
		puts book.text + ", " + book.href
	end
end

exit 0

