#!/usr/bin/env ruby

require 'selenium-webdriver'
require 'set'
require 'curb'

# define github credentials
github_email = 'YOUR GITHUB EMAIL ADDRESS'
github_password = 'YOUR GITHUB PASSWORD'

# define download dir, and get a list of existing files
download_dir = './downloads'
Dir.mkdir download_dir
Dir.chdir download_dir
existing_files = Dir.entries download_dir

# create new webdriver
driver = Selenium::WebDriver.for :firefox

# log into railscasts via github
driver.navigate.to 'http://railscasts.com/login'
driver.find_element(:id, 'login_field').send_keys github_email
element = driver.find_element(:id, 'password')
element.send_keys github_password
element.submit

# setup variables to contain navigation and episode links
nav_links_unscanned = ['http://railscasts.com/?page=1&view=list']
nav_links_scanned = []
episode_links = Set.new

# get a unique list of episode links
while !nav_links_unscanned.empty?
  link = nav_links_unscanned.shift
  nav_links_scanned << link

  driver.navigate.to link
  a_tags = driver.find_elements(:tag_name, 'a')
  a_tags.each do |a|
    # check for episode link
    if a[:href] =~ /.*\/episodes\/[0-9]+.*(?<!view=comments)$/
      episode_links << a[:href]
    # check for navigation link
    elsif a[:href] =~ /page.*view=list/ && !nav_links_unscanned.include?(a[:href]) && !nav_links_scanned.include?(a[:href])
      nav_links_unscanned << a[:href]
    end
  end

end

# loop through episode links and download movies
episode_links.each do |link|
  driver.navigate.to link

  # get movie link
  e = driver.find_element(:link_text, 'mp4')

  # download file
  file_name = e[:href].split('/').last
  if !existing_files.include?(file_name)
    existing_files << file_name
    puts "Downloading: #{e[:href]}\n"
    curld = Curl.get(e[:href])
    File.open(file_name, 'w') {|f| f.write(curld.body_str) }
  end

end

driver.quit
