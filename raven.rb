#!/usr/bin/env ruby

# === === === === === === === === === === === === === === === === === === === #
# filename: raven.rb
#
# This is the module to interact with the Twitter API, involving sending and
# pulling images from the platform
# === === === === === === === === === === === === === === === === === === === #

require "json"
require "open-uri"
require "optparse"
require "twitter"

class Raven
  def initialize( auth )
    @client = Twitter::REST::Client.new auth
  end

  # ================ #
  # TWITTER HANDLING #
  # ================ #

  def get_tweet( id, mode='extended' )
    @client.status id, tweet_mode: mode
  end

  def get_tags( id )
    get_tweet( id ).hashtags
  end

  # retrieves an image from a given media URL
  def pull_img_from_url( url, output )
    raise TypeError,     'gimme url'     if !url.instance_of? Addressable::URI
    raise ArgumentError, 'gimme png out' if !png? output

    open( output, 'wb' ) do |out|
      # using 'open-uri' to pull data from url into output
      out << open( url.normalize.to_s ).read
    end
  end

  # ========== #
  # VALIDATION #
  # ========== #

  private

  # checks if a tweet is valid for parsing by our steganographer
  # a tweet is valid iff:
  #   + it has media
  #   + the media are pngs
  #   + TODO more validation based on steganographer
  def valid_tweet?( tweet )
    raise TypeError, 'gimme tweet' if !tweet.instance_of? Twitter::Tweet
    valid = tweet.media?

    if valid
      tweet.media.each { |m| valid = valid && m.type.eql?( 'photo' ) && media_is_png?( m ) }
    end

    valid
  end

  # checks if a string is a png file
  def png?( str )
    raise TypeError, 'gimme string' if !str.instance_of? String
    str.end_with?( '.png' )
  end

  def url_is_png?( url )
    raise TypeError, 'gimme url' if !url.instance_of? Addressable::URI
    png? url.to_s
  end

  def media_is_png?( media )
    raise TypeError, 'gimme photo' if !media.instance_of? Twitter::Media::Photo
    url_is_png? media.media_url_https
  end
end

# @client.user_timeline.each do |t|
#   t.media.each do |m|
#     p m.type
#     p m.sizes
#     p m.indices
#     url = m.media_url_https
#     open( 'image.png', 'wb' ) do |file|
#       file << open( url.normalize.to_s ).read
#     end
#   end
# end

# me = @client.user 'ravenmasker'
# p @client.user_timeline 'ravenmasker'
