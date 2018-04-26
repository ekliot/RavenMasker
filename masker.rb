#!/usr/bin/env ruby

# === === === === === === === === === === === === === === === === === === === #
# filename: masker.rb
#
# This is the module to store messages into PNG files, as well as exracting
# those messages
# === === === === === === === === === === === === === === === === === === === #

require "chunky_png"

class Masker

  Grid = Struct.new( :cell_size, :grid_size, keyword_init: true ) do
  end

  # ================ #
  # INSTANCE METHODS #
  # ================ #

  def initialize( img, msg, tags=[] )
    raise TypeError, 'gimme ChunkyPNG::Image' if !img.instance_of? ChunkyPNG::Image
    raise TypeError, 'gimme String' if !msg.instance_of? String
    raise TypeError, 'gimme Array' if !tags.instance_of? Array

    @img = img
    @msg = msg
    @tags = tags
  end

  def get_grid()
    p self.class.get_grid @img, @msg
  end

  # ============= #
  # CLASS METHODS #
  # ============= #

  def self.get_grid( img, msg )
    w = img.width
    h = img.height
    l = msg.length

    p "img // [ #{w}, #{h} ] px"
    p "msg // #{l} chars"

    # these are automatically Ints, as integer division in Ruby does not cast values as floats
    cell_w = w / l
    cell_h = h / l

    raise ArgumentError, 'message too long for image' if cell_w < 1 || cell_h < 1

    grid_w = w / cell_w
    grid_h = h / cell_h

    p "cells // [ #{cell_w}, #{cell_h} ] px"
    p "grid // [ #{grid_w}, #{grid_h} ] cells"

    return Grid.new(
      cell_size: [ cell_w, cell_h ],
      grid_size: [ grid_w, grid_h ]
    )
  end

  def self.open_png( fname )
    return ChunkyPNG::Image.from_file( fname )
  end

  def self.compare_pngs( a, b )
    return if a.width != b.width || a.height != b.height

    for r in 0...a.width
      for c in 0...a.height
        p "nope" if a[r,c] != b[r,c]
      end
    end
  end
end

img = Masker.open_png( 'sword01.png' )
m = Masker.new img, 'do you want to live forever?'
m.get_grid()
