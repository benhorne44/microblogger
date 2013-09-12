###
# MicroBlogger v1.0
# by Simon Taranto and Ben Horne
# Completed 9/12/13
###

require 'jumpstart_auth'
require 'certified'
require 'bitly'
require 'klout'

Bitly.use_api_version_3

class MicroBlogger
  attr_reader :client

  def initialize
    puts "Initializing!"
    Klout.api_key = 'xu9ztgnacmjx3bu82warbr3h'
    @client = JumpstartAuth.twitter
    @screen_names = @client.followers.collect{|follower| follower.screen_name.downcase}
    @friends = @client.friends
  end

  def run
    puts "Welcome to the JSL Twitter Client!"
    while @command != "quit"
      printf "enter command:"
      input = gets.chomp
      execute_command(input)
    end
  end

  def klout_score
    @screen_names.each do |human|
      identity = Klout::Identity.find_by_screen_name(human) rescue nil
      if identity.nil?
        puts "#{human} is a scrub. Go get some friends. Be nice."
      else
        user = Klout::User.new(identity.id)
        popularity = user.score.score.round(4)
        puts "#{human}'s popularity is".ljust(40, ".") + "#{popularity}!"
      end
    end
  end

  def tweet(message)
    if message.length <= 140
      @client.update(message)
      puts "You've been tweeted!"
    else
      puts "WARNING! You have exceeded the 140 character limit, dummy!"
    end
  end

  def spam_my_followers(message)
    @screen_names.each do |follower|
      dm(follower, message)
    end
  end

  def dm(target, message)
    puts "Starting to send '#{target}' this direct message:"
    puts message
    target = target.downcase
    if @screen_names.include?(target)
      dm_string = "d #{target} #{message}"
      tweet(dm_string)
      puts "Sent the message!"
    else
      puts "Yo fool, '#{target}' doesn't follow you."
    end
  end

  def everyones_last_tweet
    sorted_friends = @friends.sort_by{ |friend| friend.screen_name.downcase }

    sorted_friends.each do |friend|
      last_message = friend.status.text
      screen_name  = friend.screen_name
      timestamp    = friend.status.created_at
      fancy_time   = timestamp.strftime("%A, %b %d")
      puts "\n'#{screen_name}' said this on #{fancy_time}...\n"
      puts "\t#{last_message}"
    end
  end

  def check_command?(command,message)
    a = ['t', 'dm', 'spam', 's', 'turl']
    a.include?(@command) && message.length == 0
  end

  def execute_command(input)
    parts    = input.split(" ")
    @command = parts[0]
    message  = parts[1..-1].join(" ")

    if check_command?(@command,message)
      puts "Please include text with your command."
    else
      case @command
        when 'quit' then puts "Goodbye!"
        when 't'    then tweet(message)
        when 'dm'   then dm(parts[1], parts[2..-1].join(" "))
        when 'spam' then spam_my_followers(message)
        when 'elt'  then everyones_last_tweet
        when 's'    then shorten(message)
        when 'turl' then tweet(parts[1..-2].join(" ") + " " + shorten(parts[-1]))
        when 'klout' then klout_score
        else 
          puts "Sorry, I don't know how to #{@command}"
      end
    end
  end

  def shorten(original_url)
    bitly = Bitly.new('hungryacademy','R_430e9f62250186d2612cca76eee2dbc6')
    short_url = bitly.shorten(original_url).short_url
    return short_url
  end

end

blogger = MicroBlogger.new
blogger.run
# blogger.klout_score

