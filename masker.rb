#!/usr/bin/env ruby

# === === === === === === === === === === === === === === === === === === === #
# filename: masker.rb
#
# This is the module to store messages into PNG files, as well as exracting
# those messages
# === === === === === === === === === === === === === === === === === === === #

require "chunky_png"

def open_png( fname )
  return ChunkyPNG::Image.from_file( fname )
end

def compare_pngs( a, b )
  return if a.width != b.width || a.height != b.height

  for r in 0...a.width
    for c in 0...a.height
      p "oops" if a[r,c] != b[r,c]
    end
  end
end

get = open_png( "test.png" )
had = open_png( "sword01.png" )

compare_pngs get, had
#
# open_png( "test.png" ).each do |px|
#   p px
# end
