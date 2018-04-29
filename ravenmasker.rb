#!/usr/bin/env ruby

# === === === === === === === === === === === === === === === === === === === #
# filename: ravenmasker.rb
# === === === === === === === === === === === === === === === === === === === #

require 'thor'
require_relative 'masker'
require_relative 'raven'

class RavenMasker < Thor
  # override implemented from https://stackoverflow.com/a/45730659/5103831
  # this is to make sure the ordering of commands is true to the ordering here
  class << self
    def help(shell, subcommand = false)
      list = printable_commands(true, subcommand)
      Thor::Util.thor_classes_in(self).each do |klass|
        list += klass.printable_commands(false)
      end

      # Remove this line to disable alphabetical sorting
      # list.sort! { |a, b| a[0] <=> b[0] }

      # Add this line to remove the help-command itself from the output
      list.reject! {|l| l[0].split[1] == 'help'}

      if defined?(@package_name) && @package_name
        shell.say "#{@package_name} commands:"
      else
        shell.say "Commands:"
      end

      shell.print_table(list, :indent => 2, :truncate => false)
      shell.say
      class_options_help(shell)

      # Add this line if you want to print custom text at the end of your help output.
      # (similar to how Rails does it)
      shell.say 'All commands can be run with -h (or --help) for more information.'
    end
  end

  desc 'mask <img> <msg> <tags>', 'encrypt <msg> into <img> using <tags>'
  def mask( img_name, msg, tags )
    begin
      Masker.img_valid? img_name
    rescue => err
      @shell.say "Provided image file, #{img_name}, is not valid..."
      @shell.say "\t#{err.message}"
      return
    end

    begin
      Masker.msg_valid? msg
    rescue => err
      @shell.say "Provided message, #{msg}, is not valid..."
      @shell.say "\t#{err.message}"
      return
    end

    begin
      Masker.tags_valid?( tags.split ',' )
    rescue => err
      @shell.say "Provided tags, #{tags}, are not valid..."
      @shell.say "\t#{err.message}"
      @shell.say "\tMake sure to provide tags as a comma-separated string"
      return
    end

    puts "#{msg} will be encrypted in #{img_name} using #{tags}"
  end

  desc 'unmask <img> <tags>', 'decrypt a message from <img> using <tags>'
  def unmask( img, tags )
    puts "decrypting #{img} using #{tags}"
  end

  desc 'pull <status>', 'read <status> tweet and check for an encrypted message'
  def pull()
    @auth = JSON.parse( File.read( __dir__ + '/auth.json' ) )
  end

  desc 'send <img> <msg> <tweet> <tags> <auth>', 'tweet <tweet> with <msg> encrypted into <img> using <tags> from <auth> user'
  def send()
    @auth = JSON.parse( File.read( __dir__ + '/auth.json' ) )
  end

end


RavenMasker.start( ARGV )
