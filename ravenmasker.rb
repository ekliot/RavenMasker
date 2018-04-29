#!/usr/bin/env ruby

# === === === === === === === === === === === === === === === === === === === #
# filename: ravenmasker.rb
# === === === === === === === === === === === === === === === === === === === #

require 'thor'

class RavenMasker < Thor
  desc 'mask IMG MSG TAGS', 'encrypt MSG into IMG using TAGS'
  desc 'unmask IMG TAGS', 'decrypt a message from IMG using TAGS'
  desc 'pull STATUS', 'read STATUS tweet and check for an encrypted message'
  desc 'send IMG MSG TWEET TAGS AUTH', 'tweet TWEET with MSG encrypted into IMG using TAGS from AUTH user'

  def mask()
  end

  def unmask()
  end

  def pull()
    @auth = JSON.parse( File.read( __dir__ + '/auth.json' ) )
  end

  def send()
    @auth = JSON.parse( File.read( __dir__ + '/auth.json' ) )
  end

end


RavenMasker.start( ARGV )
