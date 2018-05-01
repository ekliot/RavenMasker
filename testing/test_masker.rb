require 'minitest/autorun'
require_relative '../masker'

# img = 'testing/test_small.png'
# img_masked = 'testing/test_small_masked.png'
# msg = "do you want to live forever?"
# tags = [ 'valeria', 'arnold', 'crom' ]
#
# p Masker.mask img, msg, tags
# p Masker.unmask img_masked, tags

class TestMasker < Minitest::Test
  def setup
    # load test cases
  end

  #
  # Masker::Grid
  #

  def test_that_grid_gets_unique_pixels
    c_size = { w: 3, h: 3 }
    g_size = { w: 3, h: 3 }

    g = Masker::Grid.new( cell_size: c_size, grid_size: g_size )

    test_arr = []

    g.grid_len().times do |_g|
      g.cell_len().times do |_c|
        test_arr << g.get_px( _g, _c )
      end
    end

    assert_equal test_arr.uniq.length, test_arr.length
  end

  #
  # Masker core methods
  #

  # TODO these ought to be broken up
  def test_that_masking_works
  end

  # TODO these ought to be broken up
  def test_that_unmasking_works
  end

  #
  # Masker core helpers
  #

  # we want to be sure that a given img and tagset return accurate grids
  def test_that_grid_generation_is_accurate
  end

  # we want to make sure that grids are not made for
  # imgs that are too small for provided tags
  def test_that_grids_do_not_work_for_small_imgs
  end

  # we want to be sure that a given grid and
  # rng return return the expected pixel coordinates
  def test_that_px_return_is_accurate
  end

  # we want to be sure that when a pixel is set for a character, the
  # alpha offset is correct at the right pixel on the image
  def test_that_char_setting_is_accurate
  end

  # we want to be sure that given an image, px, and
  # rng, the proper char is returned
  def test_that_getting_chars_is_accurate
    # set seed, make rng
    # set png
    # set px [0,0] of png to 'a' value and add rng val
    # call get_char_at_px with new rng and that png for [0,0]
  end

  #
  # Masker tag helpers
  #

  def test_that_non_arrays_are_invalid
  end

  def test_that_empty_tags_are_invalid
  end

  def test_that_non_are_invalid
  end

  def test_that_grid_params_are_accurate
  end

  def test_that_seed_generation_is_accurate
  end

  def test_that_rng_object_is_accurate
  end

  #
  # Masker img helpers
  #

  def test_that_pngs_are_opened
  end

  def test_that_only_pngs_are_opened
  end

  def test_that_identical_pngs_are_equal
  end

  def test_that_diff_pngs_are_unequal
  end
end
