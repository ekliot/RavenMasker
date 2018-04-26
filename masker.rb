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
    def cell_len()
      cell_size[:w] * cell_size[:h]
    end

    def grid_len()
      grid_size[:w] * grid_size[:h]
    end

    def get_px( grid, cell )
      raise ArgumentError, 'grid idx out of range' if grid >= grid_len()
      raise ArgumentError, 'cell idx out of range' if cell >= cell_len()

      g_row = grid / grid_size[:w]
      g_col = grid - g_row * grid_size[:h]

      c_row = cell / cell_size[:w]
      c_col = cell - c_row * cell_size[:h]

      # return a 0-indexed (x, y) co-ord
      { x: g_col * cell_size[:w] + c_col,
        y: g_row * cell_size[:h] + c_row }
    end
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
    self.class.get_grid @img, @msg
  end

  # ============= #
  # CLASS METHODS #
  # ============= #

  def self.get_grid( img, msg )
    w = img.width
    h = img.height
    l = msg.length

    # these are automatically Ints, as integer division in Ruby does not cast values as floats
    cell_w = w / l
    cell_h = h / l

    raise ArgumentError, 'message too long for image' if cell_w < 1 || cell_h < 1

    # these are also Ints like above
    grid_w = w / cell_w
    grid_h = h / cell_h

    Grid.new(
      cell_size: { w: cell_w, h: cell_h },
      grid_size: { w: grid_w, h: grid_h }
    )
  end

  def self.open_png( fname )
    return ChunkyPNG::Image.from_file( fname )
  end

  def self.same_pngs?( a, b )
    return false if a.width != b.width || a.height != b.height

    for r in 0...a.width
      for c in 0...a.height
        return false if a[r,c] != b[r,c]
      end
    end

    true
  end
end

img = Masker.open_png( 'sword01.png' )
m = Masker.new img, 'do you want to live forever?'
g = m.get_grid()
p g
