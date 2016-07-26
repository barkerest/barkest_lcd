require 'test_helper'

class SimpleGraphicTest < Test::Unit::TestCase

  SAMPLE_WIDTH = 64
  SAMPLE_HEIGHT = 64

  class GraphicSample
    include BarkestLcd::SimpleGraphic
    def initialize
      init_graphic(SAMPLE_WIDTH, SAMPLE_HEIGHT)
    end

    def clean!
      clear_dirty
    end
  end

  def setup
    @gfx = GraphicSample.new
  end

  test 'should report correct dimensions' do
    assert_equal SAMPLE_WIDTH, @gfx.width
    assert_equal SAMPLE_HEIGHT, @gfx.height
  end

  test 'should be able to set/get bits' do
    # pixel itself should be false.
    assert_equal false, @gfx.get_bit(1, 1)

    # pixels around it should be false.
    assert_equal false, @gfx.get_bit(0, 0)
    assert_equal false, @gfx.get_bit(2, 1)
    assert_equal false, @gfx.get_bit(1, 0)
    assert_equal false, @gfx.get_bit(1, 2)

    # set the pixel and it should be true.
    @gfx.set_bit(1, 1, true)
    assert_equal true, @gfx.get_bit(1, 1)

    # pixels around it should be false still.
    assert_equal false, @gfx.get_bit(0, 0)
    assert_equal false, @gfx.get_bit(2, 1)
    assert_equal false, @gfx.get_bit(1, 0)
    assert_equal false, @gfx.get_bit(1, 2)

    # clear the pixel and it should be false again.
    @gfx.set_bit(1, 1, false)
    assert_equal false, @gfx.get_bit(1, 1)
  end

  test 'should not allow setting invalid pixels' do
    assert_raise BarkestLcd::SimpleGraphic::InvalidPosition do
      @gfx.set_bit(-1, 0)
    end
    assert_raise BarkestLcd::SimpleGraphic::InvalidPosition do
      @gfx.set_bit(0, -1)
    end
    assert_raise BarkestLcd::SimpleGraphic::InvalidPosition do
      @gfx.set_bit(-1, -1)
    end
    assert_raise BarkestLcd::SimpleGraphic::InvalidPosition do
      @gfx.set_bit(@gfx.width, 0)
    end
    assert_raise BarkestLcd::SimpleGraphic::InvalidPosition do
      @gfx.set_bit(@gfx.width, @gfx.height)
    end
    assert_raise BarkestLcd::SimpleGraphic::InvalidPosition do
      @gfx.set_bit(0, @gfx.height)
    end
  end

  test 'should clear' do
    @gfx.set_bit 10, 10, true
    assert_equal true, @gfx.get_bit(10, 10)
    @gfx.clear
    assert_equal false, @gfx.get_bit(10, 10)
  end

  test 'should set dirty when changes are made' do
    @gfx.clean!
    assert_equal false, @gfx.dirty?

    @gfx.set_bit(1, 1, true)
    assert_equal true, @gfx.dirty?

    @gfx.clean!
    assert_equal false, @gfx.dirty?
    @gfx.set_bit(1, 1, true)
    assert_equal false, @gfx.dirty?
    @gfx.set_bit(1, 1, false)
    assert_equal true, @gfx.dirty?

    # TODO: need to add 'clear', 'hline', 'vline', 'line', and 'rect' to the tests.
  end

end