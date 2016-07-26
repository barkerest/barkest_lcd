require 'models/simple_graphic'

BarkestLcd::PicoLcdGraphic.class_eval do
  include BarkestLcd::SimpleGraphic

  init_hook :init_display


  ##
  # Width of the screen in pixels.
  SCREEN_W      = 256

  ##
  # Height of the screen in pixels.
  SCREEN_H      = 64

  ##
  # Default contrast for the screen.
  DEFAULT_CONTRAST  = 0xE5

  ##
  # Default brightness for the screen.
  DEFAULT_BACKLIGHT = 0x7F


  ##
  # Sets the backlight level.
  def backlight(level = 0xFF)
    level &= 0xFF
    write [ OUT_REPORT.LCD_BACKLIGHT, level ]
    self
  end


  ##
  # Sets the contrast level.
  def contrast(level = 0xFF)
    level &= 0xFF
    write [ OUT_REPORT.LCD_CONTRAST, level ]
    self
  end


  ##
  # Sends the screen contents to the device.
  def paint(force = false)
    if dirty? || force
      # 4 chips each holding 64x64 of data.
      (0..3).each do |csi|
        cs = (csi << 2)
        # each memory line holds 64 bytes, or 8 rows of data.
        (0..7).each do |line|
          # use dirty rectangles to avoid sending unnecessary data to the device.
          if force || dirty_rect?(csi * 64, line * 8, 64, 8)
            # send the data in two packets for each memory line.
            packet_1 = [ OUT_REPORT.CMD_DATA, cs, 0x02, 0x00, 0x00, 0xb8 | line, 0x00, 0x00, 0x40, 0x00, 0x00, 32 ]
            packet_2 = [ OUT_REPORT.DATA, cs | 0x01, 0x00, 0x00, 32 ]

            (0..63).each do |index|
              # each byte holds the data for 8 rows.
              byte = 0x00
              (0..7).each do |bit|
                x = (csi * 64) + index
                y = ((line * 8) + bit) % height

                byte |= (1 << bit) if get_bit(x, y)
              end

              # add the byte to the correct packet.
              (index < 32 ? packet_1 : packet_2) << byte
            end
            # send the packets.
            write packet_1
            write packet_2
          end
        end
      end
      clear_dirty
    end
    self
  end


  private

  def init_display(_)
    init_graphic SCREEN_W, SCREEN_H
    loop_hook { |_| paint }
  end


end