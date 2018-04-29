#!/usr/bin/env ruby

# === === === === === === === === === === === === === === === === === === === #
# filename: masker.rb
#
# This is the class to store messages into PNG files, as well as exracting
# those messages from encrypted PNGs
# === === === === === === === === === === === === === === === === === === === #

require 'chunky_png'

class Masker

  # TODO document
  Coord = Struct.new( :x, :y, keyword_init: true )

  # TODO document
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
      g_col = grid % grid_size[:w]

      c_row = cell / cell_size[:w]
      c_col = cell % cell_size[:w]

      # return a 0-indexed (x, y) co-ord
      Coord.new(
        x: g_col * cell_size[:w] + c_col,
        y: g_row * cell_size[:h] + c_row
      )
    end
  end

  HASHTAG_REGEX = /^[a-zA-Z_]\w*$/

  # ============ #
  # CORE METHODS #
  # ============ #

  # --- Masker.mask( img_name, msg, tags )
  # TODO document
  def self.mask( img_name, msg, tags )
    pid = fork do
      orig = self.open_png img_name
      img = ChunkyPNG::Image.from_canvas orig

      # TODO validate img
      # TODO validate message
      self.tags_valid?( tags )

      rng = Masker.gen_rng tags
      grid = Masker.gen_grid img, tags

      # keep track of which coordinates have already been set
      set_px = []

      msg.split('').each do |ch|
        px = self.next_px grid, rng
        while set_px.include? px
          px = self.next_px grid, rng
        end
        self.set_char_at_px img, px, ch, rng
        set_px << px
      end

      new_name = img_name.chomp( '.png' )
      new_name << '_masked.png'

      img.save new_name
    end

    Process.wait pid
  end

  # --- Masker.unmask( img_name, tags )
  # TODO document
  def self.unmask( img_name, tags )
    r, w = IO.pipe

    fork do
      r.close

      img = self.open_png img_name
      grid = self.gen_grid img, tags
      rng = self.gen_rng tags

      px = self.next_px grid, rng
      ch = self.get_char_at_px img, px, rng

      # keep track of which coordinates have already been set
      set_px = []

      # keep going until we get to a 'NUL' terminating value
      while !ch.nil?
        # push the character into our message
        w << ch
        # flag the coordinate as traversed
        set_px << px

        # keep picking new pixels until we get to an unseen one
        px = self.next_px grid, rng
        while set_px.include? px
          px = self.next_px grid, rng
        end

        # get its character
        ch = self.get_char_at_px img, px, rng
      end

      w.close
    end

    w.close

    msg = ''
    msg << r.read

    r.close

    msg
  end

  # ============ #
  # CORE HELPERS #
  # ============ #

  # --- Masker.gen_grid( img, tags )
  # TODO document
  def self.gen_grid( img, tags )
    raise TypeError, 'gimme ChunkyPNG::Image' if !img.instance_of? ChunkyPNG::Image

    w = img.width
    h = img.height
    g_val = self.get_grid_param( tags )

    # the following divisions are automatically Ints, as integer division
    # in Ruby does not cast values as floats

    # how big is each cell of the grid?
    cell_w = w / g_val
    cell_h = h / g_val

    raise ArgumentError, 'image too small for hash tags' if cell_w < 1 || cell_h < 1

    # how many cells are in our grid?
    grid_w = w / cell_w
    grid_h = h / cell_h

    Grid.new(
      cell_size: { w: cell_w, h: cell_h },
      grid_size: { w: grid_w, h: grid_h }
    )
  end

  # --- Masker.next_px( grid, rng )
  # TODO document
  def self.next_px( grid, rng )
    raise TypeError, 'gimme Grid' if !grid.instance_of? Masker::Grid
    raise TypeError, 'gimme Random' if !rng.instance_of? Random

    g_max = grid.grid_len()
    c_max = grid.cell_len()

    g = rng.rand g_max
    c = rng.rand c_max

    grid.get_px g, c
  end

  # --- Masker.set_char_at_px( img, px, ch, rng )
  # TODO document
  # this assumes the image has already been validated
  # and does not have any pre-existing transparency
  def self.set_char_at_px( img, px, ch, rng )
    colour = img[px[:x], px[:y]]

    ord = ch.ord
    # this is just some noise
    offset = rng.rand( (255 - 128)/2 )

    alpha = (ChunkyPNG::Color.a colour) - ord - offset
    hex = ChunkyPNG::Color.to_hex colour

    img[px[:x], px[:y]] = ChunkyPNG::Color.from_hex hex, alpha
  end

  # --- Masker.char_at_px( img, px, rng )
  # TODO document
  def self.get_char_at_px( img, px, rng )
    colour = img[px[:x], px[:y]]
    alpha = ChunkyPNG::Color.a colour

    # if the pixel has no transparency, it has no data -- abort
    return nil if alpha == 255

    offset = alpha + rng.rand( (255 - 128)/2 )
    ord = 255 - offset

    # if the offset gave us a bogus (non-ASCII) value -- abort
    return nil if !ord.between? 0, 128

    ord.chr
  end

  # =========== #
  # TAG PARSING #
  # =========== #

  # --- Masker.gen_rng( tags )
  # returns a fresh Random object using a hashtag-derived seed value
  def self.gen_rng( tags )
    Random.new self.gen_seed tags
  end

  # --- Masker.gen_seed( tags )
  # this generates a PRNG seed based on a set of given hashtags
  #
  # seed generation (TODO room for improvement?):
  #   - each tag has the product of its ASCII codes raised to the
  #     power of its length
  #   - these are then multiplied together
  #   - this product is then divided by the average ASCII value of all hashtags
  #   - this is then multiplied by the number of hashtags
  def self.gen_seed( tags )
    self.tags_valid? tags

    seed = 1
    buffer = 1
    sum = 0
    count = 0

    tags.each do |tag|
      tag.split('').each do |c|
        buffer *= c.ord
        sum += c.ord
        count += 1
      end
      buffer = buffer ** tag.length
      seed *= buffer
      buffer = 1
    end

    (seed / (sum/count)) * tags.length
  end

  # --- Masker.get_grid_param( tags )
  # here we derive a value used to generate the image Grid
  #   - currently it's the average ASCII val of all hashtag characters
  #   - this lets it be relatively meaningful for any combination of
  #     hashtags (that is, it will make a good grid for most images)
  #   - TODO consider ways to put more variance into this -- really, we want
  #     it to be big enough to account for a message of reasonable size but
  #     not so big it's out of the image's bounds
  #       - minimally, atleast the length of the message to be encrypted
  #       - maximally, the minimum of image width or height (ideally no more
  #         than a third of either)
  #
  # the variables we can play with to get this value:
  #   - how many tags there are
  #   - the order of tags and/or their characters
  #   - the length of tags
  #   - ascii codes of chars in tags
  def self.get_grid_param( tags )
    self.tags_valid? tags

    sum = 0
    count = 0

    tags.each do |t|
      t.split.each do |c|
        sum += c.ord
        count += 1
      end
    end

    sum / count
  end

  # ========== #
  # VALIDATORS #
  # ========== #

  # --- Masker.tags_valid?( tags )
  # validates an Array of Strings to make sure they are Twitter-acceptable
  #   - each hashtag must be alphanumeric (including underscores) and cannot
  #     start with a number
  #   - the combined length of all hashtags cannot exeeed
  #     280-(tags.length*2)+1 (max length of a tweet, #'s and spaces
  #     between each hashtag)
  #   - each hashtag must be ASCII
  def self.tags_valid?( tags )
    raise TypeError, 'tags must be an Array' if !tags.is_a? Array
    raise ArgumentError, 'given tags are empty' if tags.length == 0

    ch_cnt = 0
    max_len = 281 - (tags.length * 2)

    tags.each do |t|
      raise TypeError, "tag #{t} must be a String" if !t.is_a? String
      raise ArgumentError, "tag #{t} must be ASCII characters" if !t.ascii_only?
      raise ArgumentError, "tag #{t} does not match Twitter hashtag pattern" if !t.match? HASHTAG_REGEX
      ch_cnt += t.length
      raise ArgumentError, 'length of tags is too long for Twitter' if ch_cnt > max_len
    end

    return true
  end

  # --- Masker.img_valid?( img_name )
  def self.img_valid?( img_name )
    raise TypeError, 'image filename must be a String' if !img_name.is_a? String
    raise ArgumentError, 'image filename must be a PNG' if !img_name.end_with? '.png'
    raise ArgumentError, 'could not find image' if !File.exist? img_name
    return true
  end

  # --- Masker.img_valid?( img )
  def self.msg_valid?( msg )
    raise TypeError, "message #{msg} must be a String" if !msg.is_a? String
    raise ArgumentError, "message #{msg} must be ASCII characters" if !msg.ascii_only?
    return true
  end

  # =========== #
  # PNG HELPERS #
  # =========== #

  # TODO document
  def self.open_png( fname )
    return ChunkyPNG::Image.from_file( fname )
  end

  # TODO document
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
