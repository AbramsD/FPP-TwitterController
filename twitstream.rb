require 'twitter'
require 'net/http'
require 'pp'
require 'json'

def processTweet (tweet)
	if tweet.user.screen_name == "SwobodaLights"
		return
	end

    if tweet.retweet_count > 0
    	puts "oops We're Out! 2"
    	return
    end 

    #don't respond if this is a reply to a tweet that I didn't send!
    if tweet.in_reply_to_screen_name != nil && tweet.in_reply_to_screen_name != "SwobodaLights"
    	puts "oops We're out! 1"
    	return
    end


	
	##TODO:: Check if it's a Chief's Tweet  Maybe a Touchdown Dance is required?!
	if tweet.user.screen_name == "Chiefs"
		puts "Oops We're out! 3"
		return
	end

	##Todo check to see if this is a reply to a message I sent
	## otherwise if it's a reply and not to me, get the hell out.

	# TODO: Check GEO Positioning data.  See if it's close
	#otherwise respond and get out!

	#Was it a Start the Show Command?
	text = tweet.text
	scan = "start the show"
	text.scan(/#{scan}/i) {|w| 
		return startShow(tweet)
	}

	#Did it even mention me?
	scan = "@SwobodaLights"
	text.scan(/#{scan}/i) {|w|
		sendControlMessage(tweet)
	}

end

def processDM (dm)
	puts "got a DM"
	puts direct_message.text
end

def startShow(tweet)
	## Check if show is already running
	puts "In Start Show."

	status = `/opt/fpp/bin.pi/fpp -s`
	
	statusItems = status.split(",")
	
	#check if we're currently idle If so, don't trigger a new show
	if statusItems[1].to_i == 0
		responseText = "Sorry @#{tweet.user.screen_name}. The show is not currently running.  It's up daily between 5-11pm"
		return @restClient.update(responseText, in_reply_to_status_id: tweet.id)
	end
	
	scan = "MainShow"
	puts @LastStartTime

	statusItems[3].scan("/#{scan}/") {|w|
		#We're in the main show already
		#Reply Tweet that the show is already in progress!  Tune to 107.9 FM
		responseText = "Hey @#{tweet.user.screen_name}!  The show's currently Running!  Tune
		in to 107.9 FM and enjoy, or come back and try again in 30 minutes.  Happy Holidays!"
		return @restClient.update(responseText, in_reply_to_status_id: tweet.id)
	}

    ##TODO: Check if the show has been run in the last 30 minutes.
    if (@LastStartTime + (60*30)) > Time.now
		returnTime = (Time.now - @LastStartTime).round
		#Let them know to come back in 30 minutes
		responseText = "Sorry @#{tweet.user.screen_name}.  I'm giving the Neighbors a bit of a break.  Come back in #{returnTime} minutes."
		return @restClient.update(responseText, in_reply_to_status_id: tweet.id)
	end
	#OtherWise
    puts "start the show"
    uri = URI("http://localhost/fppxml.php?command=triggerEvent&id=1_1")
    Net::HTTP.get(uri)
    @LastStartTime = Time.now

	responseText = "Hey @#{tweet.user.screen_name}!  Thanks for driving by.  The show will 
	start in 2 and 1/2 minutes.  Tune your Radio to 107.9 FM! Merry Chirstmas!"

	@restClient.update(responseText, in_reply_to_status_id: tweet.id)
end

def sendControlMessage(tweet)
	responseText = "Hey @#{tweet.user.screen_name}!  You can trigger the show to start by tweeting @SwobodaLights Start the show!"
	@restClient.update(responseText, in_reply_to_status_id: tweet.id)
end




puts "Starting Client"

@streamClient = Twitter::Streaming::Client.new do | config |
	config.consumer_key       = ''
	config.consumer_secret    = ''
	config.access_token        = ''
	config.access_token_secret = ''
end

puts "Streaming client created"

@restClient = Twitter::REST::Client.new do | config |
	config.consumer_key       = ''
	config.consumer_secret    = ''
	config.access_token        = ''
	config.access_token_secret = ''
end

puts "REST client created"

@LastStartTime = Time.now - (60 * 30)  #Last start time is assumed 30 min ago.

@streamClient.user do |object|
	case object
	when Twitter::Tweet
		processTweet(object)
	when Twitter::DirectMessage
		processDM(object)
	when Twitter::Streaming::StallWarning
		warn "Falling behind on Tweets"
	end
end

client.userstream

