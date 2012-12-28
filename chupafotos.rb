#!/usr/bin/ruby 

%w(
Copyright (C) 2012  Felipe Molina (@felmoltor, felmoltor@gmail.com)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
)

require "#{File.dirname(__FILE__)}/ChupaFotos"
require 'optparse'

def parseOptions
    opts = {:account => "", :password => "", :browser => "firefox", :delete=>false}
    parser = OptionParser.new do |opt|
        opt.banner = "Usage: #{$0} -a <account> -p <password> [options]"
        opt.separator ""
        opt.separator "Specific options: "

        opt.on("-a ACCOUNT","--account ACCOUNT","Email ro telephone of the Tuenti account (mandatory)") do |account|
            opts[:account] = account
        end
        opt.on('-p PASSWORD','--password PASSWORD', "Password for the Tuenti account (mandatory)") do |password|
            opts[:password] = password
        end
        opt.on('-d','--delete', "If specified, at the end of the process, this Tuenti account will be DELETED (default: NO)") do
            opts[:delete] = true
        end
        opt.on('-b [BROWSER]','--browser [BROWSER]', "TODO: Browser to open (default: 'firefox')") do |browser|
            opts[:browser] = browser
        end
        opt.on("-h","--help", "Print help and usage information") do
            puts parser
            exit
        end
    end # del parse do

    begin
        parser.parse($*)
        # Controlamos las opciones obligatorias
        raise OptionParser::MissingArgument if (opts[:account].nil? or opts[:account].size == 0)
        raise OptionParser::MissingArgument if (opts[:password].nil? or opts[:password].size == 0) 
    rescue OptionParser::ParseError
        puts "Error with the options provided".red
        puts parser
        exit
    end
    opts
end

def printAllAlbumsSummary(albums)
  puts "==================================="
  puts "====== #{albums.size} ALBUMS TO RETRIEVE ======="
  puts "==================================="
  puts
  albums.each{|album|
    n_photos_msg = "#{album['counter']} Photos"
    msg_len = album['title'].size+n_photos_msg.size+7
    puts "#"*msg_len
    puts "# #{album['title']} (#{n_photos_msg.magenta}) #"
    puts "#"*msg_len
    puts
  }
  puts "================================="
  puts
end

#######################
##       MAIN        ##
#######################

options = parseOptions

chupafotos = ChupaFotos.new
chupafotos.account=options[:account]
chupafotos.password=options[:password]
chupafotos.browser=options[:browser]

puts "Login into Tuenti"
if chupafotos.login
    usrname = "#{chupafotos.username}".green
    puts "Login successful for user '#{usrname}'"
    
    allAlbums = chupafotos.retrieveAllAlbumsInfo
    printAllAlbumsSummary(allAlbums)
    
	puts "===================="
	puts "= NOW, DOWNLOADING =" 
	puts "===================="
	puts

    allAlbums.each{|album|  
      puts "="*(album["title"].size+4)    
      print "=  "
      print "#{album["title"]}".on_blue
      print " = "
      puts
      # chupafotos.downloadAlbumPhotos(album_id=album["title"])
      puts "="*(album["title"].size+4)
      puts    
    }
    
	puts "Now, you can safely delete your Tuenti account!".blue
	puts
	if (options[:delete])
	  puts "You are about to unmercifully kill your Tuenti account".red
	  print "Confirm you'r not drunk and seriously willing to delete this Tuenti account [yes/NO]: "
	  confirm = $stdin.gets
	  if confirm.strip.downcase =="yes"
      puts "Bye, bye Tuenti..."
      chupafotos.deleteAccount    
	  else
	    puts "Are you a chicken?..."
	  end
	end
else
    puts "There was some problem loging in. Check if the account/password is correct".red
end


