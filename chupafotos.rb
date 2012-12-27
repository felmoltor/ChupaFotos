#!/usr/bin/ruby 

require "#{File.dirname(__FILE__)}/ChupaFotos"
require 'optparse'
require 'logger'

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
        puts "Error with the options provided"
        puts parser
        exit
    end
    opts
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
    puts "Login successful for user '#{chupafotos.username}'"
    chupafotos.retrieveAllAlbumsInfo.each{|album|
      puts "========== Downloading Album '#{album["title"]}' ========="
      chupafotos.downloadAlbumPhotos(album_id=album["title"])
      puts "================================================="
      puts      
    }
else
    puts "There was some problem loging in. Check if the account/password is correct"
end


