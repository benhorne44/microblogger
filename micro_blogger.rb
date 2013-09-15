###
# MicroBlogger v1.0
# by Simon Taranto and Ben Horne
# Completed 9/12/13
###

# PROBLEMS:
# 1.  How to call Tweet method from inside other classes
# 2.  How to pass a message if required to other classes
# 3.  How best to handle making the Twitter connection

require 'jumpstart_auth'
require 'bitly'
require 'klout'

class MicroBlogger
  attr_reader :client

  def initialize
    puts "Initializing!"
    Klout.api_key = 'ze3d847cmgg43utkyyzeuy56'
    Bitly.use_api_version_3
  end

  def run
    puts "Welcome to the JSL Twitter Client!"
      make_twitter_connections
      find_friends
    while @command != "quit"
      printf "enter command:"
      input = gets.chomp
      execute_command(input)
    end
  end

  def commands
    quit = QuitCommand.new
    tweet = TweetCommand.new(@client)
    dm = DmCommand.new
    spam = SpamCommand.new
    elt = EltCommand.new
    shorten = ShortenCommand.new
    turl = TurlCommand.new
    klout = KloutCommand.new
    no_action = NoActionCommand.new

    [ quit, tweet, dm, spam, elt, shorten, turl, klout, no_action ]
  end

  def command_for_input(command_input)
    commands.find{|command| command.match?(command_input)}
  end

  def execute_command(input)
    parts    = input.split(" ")
    @command = parts[0]
    message  = parts[1..-1].join(" ")

    command_for_input(@command).execute(message)
  end

  def make_twitter_connections
    @client = JumpstartAuth.twitter
  end

  def friends
    @friends ||= find_friends
  end

  def find_friends
    @screen_names = @client.followers.collect{|follower| follower.screen_name.downcase}
    @friends = @client.friends
  end

  def klout_score
    @screen_names.each do |human|
      sleep(0.5)
      
      identity = fetch_klout_identity(human)

      if identity
        user = Klout::User.new(identity.id)
        popularity = user.score.score.round(2)
        puts "#{human}'s popularity is".ljust(40, ".") + "#{popularity}!"
      else
        puts "#{human} is a scrub. Go get some friends. Be nice."
      end

    end
  end

  def fetch_klout_identity(human)
    Klout::Identity.find_by_screen_name(human)
  rescue
    nil
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

  def shorten(original_url)
    bitly = Bitly.new('hungryacademy','R_430e9f62250186d2612cca76eee2dbc6')
    short_url = bitly.shorten(original_url).short_url
    puts short_url
    return short_url
  end

  class QuitCommand
    def match?(command)
      command == 'quit'
    end

    def execute(message) # this 'message' param is a shim
      puts "Goodbye!"
    end
  end

  class TweetCommand

    def client # attr_reader :client
      @client
    end

    def initialize(client)
      @client = client
    end

    # def tweet(message)
    #   @client.tweet(message)
    # end

    def match?(command)
      command == 't'
    end

    def execute(message)
      tweet(message)
    end

    def tweet(message)
      if message.length <= 140
        @client.update(message)
        puts "You've been tweeted!"
      else
        puts "WARNING! You have exceeded the 140 character limit, dummy!"
      end
    end

  end

  class DmCommand
    def match?(command)
      command == 'dm'
    end

    def execute(message,parts)
      dm(parts[1], parts[2..-1].join(" "))
    end
  end

  class SpamCommand
    def match?(command)
      command == 'spam'
    end

    def execute(message)
      spam_my_followers(message)
    end
  end

  class EltCommand
    def match?(command)
      command == 'elt'
    end

    def execute
      everyones_last_tweet
    end
  end

  class ShortenCommand
    def match?(command)
      command == 'spam'
    end

    def execute
      shorten_command_execute
    end
  end

  class TurlCommand
    def match?(command)
      command == 'turl'
    end

    def execute(message)
      tweet(parts[1..-2].join(" ") + " " + shorten(parts[-1]))
    end
  end

  class KloutCommand
    def match?(command)
      command == 'kloat'
    end

    def execute
      klout_score
    end
  end

  class NoActionCommand
    def match?(command)
      
    end

    def execute
      puts "Can't deal with that command"
    end
  end

end

blogger = MicroBlogger.new
blogger.run
# blogger.klout_score

