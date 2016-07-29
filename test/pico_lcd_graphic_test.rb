require 'test_helper'

class PicoLcdGraphicTest < Test::Unit::TestCase

  def setup
    dev_list = BarkestLcd::PicoLcdGraphic.devices
    @dev = (dev_list && dev_list.count > 0) ? dev_list.first : nil
  end

  def get_answer
    (STDIN.gets.to_s.strip.downcase[0]) == 'y'
  end

  test 'should be able to open/close' do
    if @dev
      assert_equal false, @dev.open?
      @dev.open
      assert_equal true, @dev.open?
      assert_raise BarkestLcd::PicoLcdGraphic::AlreadyOpen do
        @dev.open
      end
      assert_equal true, @dev.open?
      @dev.close
      assert_equal false, @dev.open?

      # make sure re-closing is valid.
      @dev.close

      # make sure re-opening works.
      @dev.open
      assert_equal true, @dev.open?
      @dev.close
      assert_equal false, @dev.open?
    end
  end

  test 'should clear the screen' do
    if @dev

      @dev.open

      @dev.clear
      @dev.draw_rect(0, 0, @dev.width, @dev.height)
      @dev.paint

      @dev.close

      print "\nThe screen of the PicoLcdGraphic device should be empty except for a bounding rectangle.\nIs this the case?"
      assert get_answer
    end
  end

  test 'should fill the screen' do
    if @dev

      @dev.open

      @dev.clear(true)
      @dev.paint

      @dev.close

      print "\nThe screen of the PicoLcdGraphic device should be full.\nIs this the case?"
      assert get_answer
    end
  end

  test 'should draw vertical lines' do
    if @dev

      @dev.open

      @dev.clear
      @dev.width.times do |x|
        if (x / 2).odd?
          @dev.draw_vline(x, 0, @dev.height)
        end
      end
      @dev.paint

      @dev.close

      print "\nThe screen of the PicoLcdGraphic device should be full of vertical lines.\nIs this the case?"
      assert get_answer
    end
  end

  test 'should draw horizontal lines' do
    if @dev

      @dev.open

      @dev.clear
      @dev.height.times do |y|
        if (y / 2).odd?
          @dev.draw_hline(y, 0, @dev.width)
        end
      end
      @dev.paint

      @dev.close

      print "\nThe screen of the PicoLcdGraphic device should be full of horizontal lines.\nIs this the case?"
      assert get_answer
    end
  end

  test 'should draw diagonal lines' do
    if @dev

      @dev.open

      @dev.clear
      w = @dev.width
      h = @dev.height
      [ -h, -h + (h / 4), -h / 2, -h / 4,  0, h / 4, h / 2, h - (h / 4), h - 1 ].each do |y|
        @dev.draw_line 0, y, w, y + h
        @dev.draw_line 0, y + h, w, y
      end
      @dev.paint

      @dev.close

      print "\nThe screen of the PicoLcdGraphic should have a diagonal crosshatch.\nIs this the case?"
      assert get_answer
    end
  end

  test 'should handle key presses' do
    if @dev

      print "\nDo you want to test a keypad attached to your PicoLcdGraphic device?"
      if get_answer

        @dev.open

        # for our bouncing square.
        x = 4
        y = 4
        xd = -1
        yd = 1
        xm = @dev.width - 16
        ym = @dev.height - 16

        have_key = false

        @dev.on_key_down do |key|
          print "Key #{key} has just been pressed.\n"
        end

        @dev.on_key_up do |key|
          print "Key #{key} has just been released.\n"
          have_key = true
        end

        print "Press a key on the device to continue.\n"

        until have_key
          sleep 0.1
          @dev.clear
          @dev.draw_rect x, y, 16, 16
          x += xd
          if x < 0
            x = 0
            xd = 1
          elsif x > xm
            x = xm
            xd = -1
          end
          y += yd
          if y < 0
            y = 0
            yd = 1
          elsif y > ym
            y = ym
            yd = -1
          end

          @dev.loop

          if have_key
            print 'Would you like to test another key?'
            have_key = false if get_answer
            print "Press another key on the device to continue.\n"
          end
        end

        @dev.close
      end
    end
  end

end