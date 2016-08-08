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
      begin
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
      ensure
        @dev.close
      end
    end
  end

  test 'should clear the screen' do
    if @dev
      begin
        @dev.open

        @dev.clear
        @dev.draw_rect(0, 0, @dev.width, @dev.height)
        @dev.paint

        @dev.close

        print "\nThe screen of the PicoLcdGraphic device should be empty except for a bounding rectangle.\nIs this the case?"
        assert get_answer
      ensure
        @dev.close
      end

    end
  end

  test 'should fill the screen' do
    if @dev
      begin
        @dev.open

        @dev.clear(true)
        @dev.paint

        @dev.close

        print "\nThe screen of the PicoLcdGraphic device should be full.\nIs this the case?"
        assert get_answer
      ensure
        @dev.close
      end

    end
  end

  test 'should draw vertical lines' do
    if @dev
      begin
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
      ensure
        @dev.close
      end

    end
  end

  test 'should draw horizontal lines' do
    if @dev
      begin
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
      ensure
        @dev.close
      end

    end
  end

  test 'should draw diagonal lines' do
    if @dev
      begin
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
      ensure
        @dev.close
      end

    end
  end

  test 'should draw text' do
    if @dev
      begin
        @dev.open

        @dev.clear
        @dev.draw_text_box("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ 0123456789", 0, 0, @dev.width, @dev.height / 2)
        @dev.draw_text_box("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ 0123456789", 0, @dev.height / 2, @dev.width, @dev.height / 2, bold: true)
        @dev.paint

        @dev.close

        print "\nThe screen of the PicoLcdGraphic should have text displayed in both regular and bold font.\nIs this the case?"
        assert get_answer
      ensure
        @dev.close
      end

    end
  end

  test 'draw_text should handle newlines' do
    if @dev
      begin

        @dev.open

        @dev.clear
        @dev.draw_text "First line.\nSecond line."
        @dev.draw_text "\nThird line (over 20).\nFourth line (also over 20).", x: 20
        @dev.paint

        @dev.close

        print "\nThe screen of the PicoLcdGraphic should have 4 lines of text with the 3rd and 4th over some.\nIs this the case?"
        assert get_answer
      ensure
        @dev.close
      end

    end
  end

  test 'should allow specifying char spacing' do
    if @dev
      begin
        @dev.open

        @dev.clear
        @dev.draw_text 'This line has default char spacing (-1).', x: 0, y: 0
        @dev.draw_text 'This line has -2 char spacing.', x: 0, y: @dev.text_offset_bottom, char_spacing: -2
        @dev.draw_text 'This line has no char spacing modifier.', x: 0, y: @dev.text_offset_bottom, char_spacing: 0
        @dev.draw_text 'This line has +1 char spacing.', x: 0, y: @dev.text_offset_bottom, char_spacing: 1
        @dev.draw_text 'This line has +2 char spacing.', x: 0, y: @dev.text_offset_bottom, char_spacing: 2
        @dev.paint

        @dev.close

        print "\nThe screen of the PicoLcdGraphic should have text displayed with varying char spacing.\nIs this the case?"
        assert get_answer
      ensure
        @dev.close
      end

    end
  end

  test 'should handle key presses' do
    if @dev
      begin
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
      ensure
        @dev.close
      end
    end
  end

  test 'should fill rectangles' do
    if @dev
      begin
        @dev.open

        @dev.clear
        @dev.fill_rect(20, 2, 60, 24)
        @dev.fill_rect(50, 16, 60, 24, false)
        @dev.draw_rect(50, 16, 60, 24)
        @dev.fill_rect(80, 32, 60, 24)
        @dev.paint

        @dev.close

        print "\nThe screen of the PicoLcdGraphic device should have several rectangles overlapping.\nThe top and bottom rectangles should be filled.\nIs this the case?"
        assert get_answer
      ensure
        @dev.close
      end

    end
  end

  test 'should draw text boxes' do
    if @dev
      begin
        @dev.open

        @dev.clear

        # will have 1/16 of the screen as a border on left and right of each column.
        cols = [
            [ (@dev.width / 16).to_i, (@dev.width * (3.0 / 8)).to_i ],
            [ ((@dev.width / 16) * 9).to_i, (@dev.width * (3.0 / 8)).to_i ]
        ]

        # 3 pixel buffer above and below each row.
        rows = [
            [ 3, 14 ],
            [ 23, 14 ],
            [ 43, 14 ]
        ]

        # second column is inverted of first column.
        @dev.fill_rect(@dev.width / 2, 0, @dev.width / 2, @dev.height)

        @dev.draw_text_box 'Box 1', cols[0][0], rows[0][0], cols[0][1], rows[0][1], align: :center
        @dev.draw_text_box 'Box 2', cols[0][0], rows[1][0], cols[0][1], rows[1][1], align: :center, border: true
        @dev.draw_text_box 'Box 3', cols[0][0], rows[2][0], cols[0][1], rows[2][1], align: :center, fill: true, bit: false

        @dev.draw_text_box 'Box 4', cols[1][0], rows[0][0], cols[1][1], rows[0][1], align: :center, bit: false
        @dev.draw_text_box 'Box 5', cols[1][0], rows[1][0], cols[1][1], rows[1][1], align: :center, border: true, bit: false
        @dev.draw_text_box 'Box 6', cols[1][0], rows[2][0], cols[1][1], rows[2][1], align: :center, fill: true

        @dev.paint

        @dev.close

        print "\nThe screen of the PicoLcdGraphic device should have 6 text boxes.\nIs this the case?"
        assert get_answer
      ensure
        @dev.close
      end

    end
  end

  test 'text boxes should cut off overflow' do
    if @dev
      begin
        @dev.open

        @dev.clear
        @dev.draw_text_box("abcdefghijklmnopqrstuvwxyz abcdefghijklmnopqrstuvwxyz abcdefghijklmnopwrstuv", 20, 20, 60, 27, border: true)
        @dev.paint

        @dev.close

        print "\nThe screen of the PicoLcdGraphic device should have a text box with text cutoff.\nIs this the case?"
        assert get_answer
      ensure
        @dev.close
      end

    end
  end

end