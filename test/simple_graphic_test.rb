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

  test 'should set dirty when bits are changed' do
    @gfx.clear
    @gfx.clean!
    assert_equal false, @gfx.dirty?

    @gfx.set_bit(1, 1, true)
    assert_equal true, @gfx.dirty?

    # verify clean! is working.
    @gfx.clean!
    assert_equal false, @gfx.dirty?


    # trying to set a bit to the same value should not set dirty.
    @gfx.set_bit(1, 1, @gfx.get_bit(1, 1))
    assert_equal false, @gfx.dirty?

    # flipping the bit should.
    @gfx.set_bit(1, 1, !@gfx.get_bit(1, 1))
    assert_equal true, @gfx.dirty?
  end

  test 'should set dirty when hlines are drawn' do
    @gfx.clear

    @gfx.clean!
    @gfx.draw_hline(1, 1, 5)          # draw line.
    assert_equal true, @gfx.dirty?

    @gfx.clean!
    @gfx.draw_hline(1, 1, 5)          # draw line over line.
    assert_equal false, @gfx.dirty?

    @gfx.clean!
    @gfx.draw_hline(1, 1, 5, false)   # erase line.
    assert_equal true, @gfx.dirty?

    @gfx.clean!
    @gfx.draw_hline(1, 1, 5, false)   # erase non-existent line.
    assert_equal false, @gfx.dirty?
  end

  test 'should set dirty when vlines are drawn' do
    @gfx.clear

    @gfx.clean!
    @gfx.draw_vline(1, 1, 5)          # draw line.
    assert_equal true, @gfx.dirty?

    @gfx.clean!
    @gfx.draw_vline(1, 1, 5)          # draw line over line.
    assert_equal false, @gfx.dirty?

    @gfx.clean!
    @gfx.draw_vline(1, 1, 5, false)   # erase line.
    assert_equal true, @gfx.dirty?

    @gfx.clean!
    @gfx.draw_vline(1, 1, 5, false)   # erase non-existent line.
    assert_equal false, @gfx.dirty?
  end

  test 'should set dirty when lines are drawn' do
    @gfx.clear

    @gfx.clean!
    @gfx.draw_line(1, 1, 5, 5)         # draw line.
    assert_equal true, @gfx.dirty?

    @gfx.clean!
    @gfx.draw_line(1, 1, 5, 5)         # draw line over line.
    assert_equal false, @gfx.dirty?

    @gfx.clean!
    @gfx.draw_line(1, 1, 5, 5, false)  # erase line.
    assert_equal true, @gfx.dirty?

    @gfx.clean!
    @gfx.draw_line(1, 1, 5, 5, false)  # erase non-existent line.
    assert_equal false, @gfx.dirty?
  end

  test 'should set dirty when rectangles are drawn' do
    @gfx.clear

    @gfx.clean!
    @gfx.draw_rect(1, 1, 10, 10)        # draw rectangle
    assert_equal true, @gfx.dirty?

    @gfx.clean!
    @gfx.draw_rect(1, 1, 10, 10)        # draw rectangle over rectangle
    assert_equal false, @gfx.dirty?

    @gfx.clean!
    @gfx.draw_rect(1, 1, 10, 10, false) # erase rectangle
    assert_equal true, @gfx.dirty?

    @gfx.clean!
    @gfx.draw_rect(1, 1, 10, 10, false) # erase non-existent rectangle
    assert_equal false, @gfx.dirty?
  end

  test 'should set dirty when filled rectangles are drawn' do
    @gfx.clear

    @gfx.clean!
    @gfx.fill_rect(1, 1, 10, 10)        # draw rectangle
    assert_equal true, @gfx.dirty?

    @gfx.clean!
    @gfx.fill_rect(1, 1, 10, 10)        # draw rectangle over rectangle
    assert_equal false, @gfx.dirty?

    @gfx.clean!
    @gfx.fill_rect(1, 1, 10, 10, false) # erase rectangle
    assert_equal true, @gfx.dirty?

    @gfx.clean!
    @gfx.fill_rect(1, 1, 10, 10, false) # erase non-existent rectangle
    assert_equal false, @gfx.dirty?
  end

  test 'should set dirty when blitting' do
    pattern = [[0,1,0,1],[1,0,1,0],[0,1,0,1],[1,0,1,0]]
    @gfx.clear

    @gfx.clean!
    @gfx.blit(1, 1, 4, 4, pattern)      # draw the pattern
    assert_equal true, @gfx.dirty?

    @gfx.clean!
    @gfx.blit(1, 1, 4, 4, pattern)      # redraw the pattern
    assert_equal false, @gfx.dirty?

    @gfx.clean!
    @gfx.blit(1, 1, 4, 4, pattern) { |x, y, data| data[y][x] != 1 }   # reverse the pattern
    assert_equal true, @gfx.dirty?

    @gfx.clean!
    @gfx.blit(1, 1, 4, 4, pattern) { |x, y, data| data[y][x] != 1 }   # redraw the reverse pattern
    assert_equal false, @gfx.dirty?
  end

  test 'should set dirty when drawing text' do
    @gfx.clear

    @gfx.clean!
    @gfx.draw_text('Hello World', x: 0, y: 0)
    assert_equal true, @gfx.dirty?

    @gfx.clean!
    @gfx.draw_text('Hello World', x: 0, y: 0)
    assert_equal false, @gfx.dirty?

    @gfx.clean!
    @gfx.draw_text('Hello World', x: 0, y: 0, bit: false)
    assert_equal true, @gfx.dirty?

    @gfx.clean!
    @gfx.draw_text('Hello World', x: 0, y: 0, bit: false)
    assert_equal false, @gfx.dirty?

    @gfx.clear
    @gfx.clean!
    @gfx.draw_text('Hello World', x: 0, y: 0, bold: true)
    assert_equal true, @gfx.dirty?

    @gfx.clean!
    @gfx.draw_text('Hello World', x: 0, y: 0, bold: true)
    assert_equal false, @gfx.dirty?

    @gfx.clean!
    @gfx.draw_text('Hello World', x: 0, y: 0, bit: false, bold: true)
    assert_equal true, @gfx.dirty?

    @gfx.clean!
    @gfx.draw_text('Hello World', x: 0, y: 0, bit: false, bold: true)
    assert_equal false, @gfx.dirty?
  end

  test 'should set dirty when drawing text box' do
    @gfx.clear

    @gfx.clean!
    @gfx.draw_text_box('Hello World', 1, 1, 30, 15)
    assert_equal true, @gfx.dirty?

    @gfx.clean!
    @gfx.draw_text_box('Hello World', 1, 1, 30, 15)
    assert_equal false, @gfx.dirty?

    @gfx.clean!
    @gfx.draw_text_box('Hello World', 1, 1, 30, 15, bit: false)
    assert_equal true, @gfx.dirty?

    @gfx.clean!
    @gfx.draw_text_box('Hello World', 1, 1, 30, 15, bit: false)
    assert_equal false, @gfx.dirty?

    @gfx.clean!
    @gfx.draw_text_box('Hello World', 1, 1, 30, 15, bold: true)
    assert_equal true, @gfx.dirty?

    @gfx.clean!
    @gfx.draw_text_box('Hello World', 1, 1, 30, 15, bold: true)
    assert_equal false, @gfx.dirty?

    @gfx.clean!
    @gfx.draw_text_box('Hello World', 1, 1, 30, 15, bit: false, bold: true)
    assert_equal true, @gfx.dirty?

    @gfx.clean!
    @gfx.draw_text_box('Hello World', 1, 1, 30, 15, bit: false, bold: true)
    assert_equal false, @gfx.dirty?
  end

end