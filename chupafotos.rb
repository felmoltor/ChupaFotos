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
    opts = {:account => "", :password => "", :browser => "firefox", :verbose => false}
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
        opt.on('-b [BROWSER]','--browser [BROWSER]', "Browser to open (default is 'firefox')") do |browser|
            opts[:browser] = browser
        end
        opt.on('-v','--verbose', 'Show more information about what the bot is doing') do
            opts[:verbose] = true
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
        
# m.log= Logger.new(STDOUT)

puts "Login into Tuenti"
if chupafotos.login
    usrname = "#{chupafotos.username}".green
    puts "Login successful for user '#{usrname}'"
    
    allAlbums = chupafotos.retrieveAllAlbumsInfo
    printAllAlbumsSummary(allAlbums)
    
    allAlbums.each{|album|      
      puts "===================="
      puts "= NOW, DOWNLOADING =" 
      puts "===================="
      puts
      print "=  "
      print "#{album["title"]}".on_blue
      print " = "
      puts
      chupafotos.downloadAlbumPhotos(album_id=album["title"])
      puts " ================================================="
      puts      
    }
else
    puts "There was some problem loging in. Check if the account/password is correct".red
end


