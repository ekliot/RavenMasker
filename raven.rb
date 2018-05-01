#!/usr/bin/env ruby

# === === === === === === === === === === === === === === === === === === === #
# filename: raven.rb
#
# This is the module to interact with the Twitter API, involving sending and
# pulling images from the platform
# === === === === === === === === === === === === === === === === === === === #

require "json"
require "open-uri"
require "twitter"

# HACK this hasn't been merged yet https://github.com/sferik/twitter/issues/881
module Twitter
  module REST
    class Request
      def merge_multipart_file!(options)
        key = options.delete(:key)
        file = options.delete(:file)

        options[key] = if file.is_a?(StringIO)
                         HTTP::FormData::File.new(file, content_type: 'video/mp4')
                       else
                         HTTP::FormData::File.new(file, filename: File.basename(file), content_type: mime_type(File.basename(file)))
                       end
      end
    end
  end
end

class Raven
  attr_accessor :client
  def initialize( auth )
    raise StandardError, 'need user consumer key to access Twitter'    if auth['consumer_key'].nil?
    raise StandardError, 'need user consumer secret to access Twitter' if auth['consumer_secret'].nil?
    @client = Twitter::REST::Client.new auth
  end

  # ================ #
  # TWITTER HANDLING #
  # ================ #

  def send_tweet( msg, img_name, options={} )
    raise StandardError, 'need user access token to send tweets'        if @client.access_token.nil?
    raise StandardError, 'need user access token secret to send tweets' if @client.access_token_secret.nil?

    @client.update_with_media msg, img_name, options
  end

  def get_tweet( id, mode='extended' )
    @client.status id, tweet_mode: mode
  end

  # ============== #
  # TWEET HANDLING #
  # ============== #

  def get_screen_name( tweet )
    raise TypeError, 'Did not receive Twitter::Tweet' if !tweet.instance_of? Twitter::Tweet
    tweet.user.screen_name
  end

  def get_text( tweet )
    raise TypeError, 'Did not receive Twitter::Tweet' if !tweet.instance_of? Twitter::Tweet
    tweet.attrs[:full_text]
  end

  def get_media_url( tweet, idx=0 )
    raise TypeError, 'Did not receive Twitter::Tweet' if !tweet.instance_of? Twitter::Tweet
    raise ArgumentError, 'Provided Tweet does not have media' if !tweet.media?
    tweet.media[idx].media_url_https
  end

  def pull_img_from_tweet( tweet, output=nil )
    img_name ||= get_screen_name( tweet ) + '_' + tweet.id.to_s + '.png'
    url = get_media_url tweet
    pull_img_from_url( url, img_name )
  end

  def get_tags( tweet )
    tweet.hashtags
  end

  def get_tags_as_strs( tweet )
    tags_to_strs get_tags tweet
  end

  # retrieves an image from a given media URL
  def pull_img_from_url( url, output )
    raise TypeError,     'Addressable::URI not provided' if !url.instance_of? Addressable::URI
    raise ArgumentError, 'Provided output file is not a PNG' if !png? output

    open( output, 'wb' ) do |out|
      # using 'open-uri' to pull data from url into output
      out << open( url.normalize.to_s ).read
    end

    output
  end

  def tags_to_strs( tags )
    tags.map do |t|
      raise TypeError, 'Twitter::Entity::Hashtag not provided' if !t.is_a? Twitter::Entity::Hashtag
      t.text
    end
  end

  def add_tags_to_msg( msg, tags )
    if tags.is_a? String
      tag_arr = tags.split( ',' )
    elsif tags.is_a? Array
      tag_arr = tags
    else
      @shell.say "\tERROR // Provided invalid Type for tags: #{tags.class}"
      return
    end

    new_msg = msg
    tag_arr.each { |t| new_msg += " ##{t}" }

    new_msg
  end

  def tweet_to_s( tweet )
    raise TypeError, 'Did not receive Twitter::Tweet' if !tweet.instance_of? Twitter::Tweet
    """Retrieved Tweet:
    ID:      #{tweet.id}
    User:    @#{get_screen_name tweet}
    Message: #{get_text tweet}"""
  end

  # ========== #
  # VALIDATION #
  # ========== #

  # checks if a tweet is valid for parsing by our steganographer
  # a tweet is valid iff:
  #   + it has media
  #   + the media are pngs
  def valid_tweet?( tweet )
    raise TypeError, 'Did not receive Twitter::Tweet' if !tweet.instance_of? Twitter::Tweet
    valid = tweet.media?

    if valid
      tweet.media.each { |m| valid = valid && m.type.eql?( 'photo' ) && media_is_png?( m ) }
    end

    valid
  end

  # checks if a string is a png file
  def png?( str )
    raise TypeError, 'String not provided' if !str.is_a? String
    str.end_with?( '.png' )
  end

  def url_is_png?( url )
    raise TypeError, 'Addressable::URI not provided' if !url.is_a? Addressable::URI
    png? url.to_s
  end

  def media_is_png?( media )
    raise TypeError, 'Twitter::Media::Photo not provided' if !media.is_a? Twitter::Media::Photo
    url_is_png? media.media_url_https
  end
end
