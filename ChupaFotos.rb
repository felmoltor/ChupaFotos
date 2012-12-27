# require "mechanize" # With mechanize was impossible to retrieve dynamic javascript code
require "watir"
require "htmlentities"
require "open-uri"

class ChupaFotos
    attr_accessor :account, :password, :browser
    attr_reader :username, :useralbums
    
    def initialize(account="",password="",browser="")
        @account = account
        @password = password
        @browser = browser
        @username = ""
        @useralbums = []
        @watir = initializeWatir
        @@last_progression = 0
    end
    
    # =========================================================
    
    #####################
    # PRIVATE FUNCTIONS #
    #####################
    
    private
    
    def initializeWatir
        # TODO: Allow using other browser besides firefox
        m = Watir::Browser.new
        
        return m
    end
    
    # =========================================================
    
    def isLoginSuccessful?
        # Do we have some SID cookie assigned to us?
        return (@watir.link(:id,"home_user_name").text.size > 0)
    end
    
    # =========================================================
    
    def waitForLoadingProcess
      # Every time that a page is called directly a Loading page is shown.
      # If the load takes too much to complete, the next query will fail
      while 1
          begin
            percent = @watir.span(:id,"loading_percent").text.to_i
            puts "Loading Tuenti (#{percent}%)"
            sleep(0.2)
          rescue => e
            break
          end
        end
        sleep(2)
    end
    
    # =========================================================
    
    def getUserAlbumIndex(search_album_title)
      i = 0
      
      @useralbums.each {|album|
        break if album["title"] == search_album_title
        i += 1
      }
      return i
    end
    
    # =========================================================
    
    def createDestinationFolder(album_title)
      dst_folder = "."
      nomal_ac_dir = @account.gsub(/[^a-z0-9_]/i,"_")
      nomal_al_dir = album_title.gsub(/[^a-z0-9_]/i,"_")
      if (!Dir.exists?(nomal_ac_dir))
        Dir.mkdir(nomal_ac_dir)
      end
      dst_folder = "#{nomal_ac_dir}/#{nomal_al_dir}"
      if (!Dir.exists?(dst_folder))
        Dir.mkdir(dst_folder)
      end
      return dst_folder
    end
    
    # =========================================================
    
    def getImageName(image_url)
=begin
      slash_pos=0
      image_url.size.times {|t|
        if image_url[image_url.size-t-1] == "/"
          slash_pos = t-1
          break
        end 
      }
=end
      return image_url.gsub("/","_")
    end
    
    # =========================================================
    
    def printProgression(n,total)
      progression = ((n/total)*100.0).to_i
      if ((progression % 5) == 0 and progression != @@last_progression)
        puts ""#{progression}%"
        @@last_progression = progression        
      end
    end
    
    # =========================================================
    
    def downloadAlbum(album_title)
      
      dst_folder = createDestinationFolder(album_title)
      
      useralbum_index = getUserAlbumIndex(album_title)
      @watir.goto(@useralbums[useralbum_index]["href"])
      waitForLoadingProcess
      # Click on first photo of the album
      @watir.ul(:class,"album").li(:id,/item_/).link.click
      
      @useralbums[useralbum_index]["counter"].times { |n_photo|
        image_url = @watir.imgs(:id,"photo_image")[0].src
        if image_url.size > 0
          image_name = getImageName(image_url)
          # TODO: Threads to speedup de download process of the photos
          open("#{dst_folder}/#{image_name}.jpg", 'wb') do |file|
            file << open(image_url).read
          end
        end
        @watir.link(:id,"photo_action").click
        printProgression(n_photo,@useralbums[useralbum_index]["counter"])
      }
    end
    
    # =========================================================
    
    ####################
    # PUBLIC FUNCTIONS #
    ####################
    
    public 
    
    def login
        @watir.goto("https://www.tuenti.com/?m=login")
        login_form = @watir.form(:id,"login_form")
        login_form.text_field(:id,"email").value = @account
        login_form.text_field(:id,"input_password").value = @password
        login_form.submit
        # Wait for tuenti to fully load the progress bar
        waitForLoadingProcess
        @username = @watir.link(:id,"home_user_name").text if isLoginSuccessful? 
        return @username
    end
    
    # =========================================================
    
    def retrieveAllAlbumsInfo
      @watir.goto("http://www.tuenti.com/?m=Albums&func=index")
      puts "User has #{@watir.lis(:id,/photo_album_/).size} folders of photos"
      @watir.lis(:id,/photo_album_/).each {|album_li|
        photo_counter = album_li.span(:class,"counter").text.gsub(" Fotos","").to_i
        album_link = HTMLEntities.new.decode(album_li.a.href)
        album_title = album_li.a.title.strip
        album_id = album_li.id
        puts "######################"
        puts "# #{album_title} #"
        puts "######################"
        puts
        puts "Link: #{album_id}"
        puts "Link: #{album_link}"
        puts "Counter #{photo_counter}"
        puts
        @useralbums << { 
                          "id" => album_id,
                          "title" => album_title,
                          "counter" => photo_counter,
                          "href" => album_link
                        }
      }
      return @useralbums
    end
    
    # =========================================================
    
    def downloadAlbumPhotos(album_title=nil)
      
      if (!album_title.nil?)
        downloadAlbumByTitle(album_title)
      else
        @useralbums.each{|album|
          downloadAlbumByTitle(album["title"])
        }
      end
    end
end