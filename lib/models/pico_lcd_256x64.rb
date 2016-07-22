require 'libusb'

module BarkestLcd

  ##
  # Interfaces with the picoLCD 256x64 from www.mini-box.com
  class PicoLcd256x64

    ##
    # Any of the Pico LCD errors.
    PicoLcdError = Class.new(StandardError)

    ##
    # The specified position is invalid (set_bit, get_bit, etc).
    InvalidPosition = Class.new(PicoLcdError)

    ##
    # The device has already been opened.
    AlreadyOpen = Class.new(PicoLcdError)

    ##
    # The device is not currently open.
    NotOpen = Class.new(PicoLcdError)

    ##
    # Level to turn the backlight off.
    BACKLIGHT_OFF = 0x00

    ##
    # Default level for backlight.
    BACKLIGHT_DEFAULT = 0x7F

    ##
    # Default level for contrast.
    CONTRAST_DEFAULT = 210

    ##
    # USB Vendor ID
    VENDOR_ID     = 0x04d8

    ##
    # USB Device ID
    DEVICE_ID     = 0xc002

    ##
    # Width of the screen in pixels.
    SCREEN_W      = 256

    ##
    # Height of the screen in pixels.
    SCREEN_H      = 64

    OUT_REPORT_LED_STATE        = 0x81
    OUT_REPORT_LCD_BACKLIGHT    = 0x91
    OUT_REPORT_LCD_CONTRAST     = 0x92
    OUT_REPORT_LCD_RESET        = 0x93
    OUT_REPORT_CMD              = 0x94
    OUT_REPORT_DATA             = 0x95
    OUT_REPORT_CMD_DATA         = 0x96

    IN_REPORT_POWER_STATE       = 0x01
    IN_REPORT_KEY_STATE         = 0x11
    IN_REPORT_IR_DATA           = 0x21

    PICOLCD_USB_EP_WRITE        = 0x01
    PICOLCD_USB_EP_READ         = 0x81

    STATUS_OK                   = 0x00
    STATUS_ERASE                = 0x01
    STATUS_WRITE                = 0x02
    STATUS_READ                 = 0x03
    STATUS_ERROR                = 0xFF
    STATUS_KEY                  = 0x10
    STATUS_IR                   = 0x11
    STATUS_VER                  = 0x12
    STATUS_DISCONNECTED         = 0x13


    ##
    # Gets all of the picoLCD 256x64 devices connected to the system.
    #
    # Caches the results, set +refresh+ to true if you need to update the list.
    def self.devices(refresh = false)
      @devices = nil if refresh
      @devices ||=
          begin
            devs = LIBUSB::Context.new
                       .devices(idVendor: VENDOR_ID, idProduct: DEVICE_ID)
                       .map{ |dev| PicoLcd256x64.new(dev) }
            devs.delete(nil)
            devs
          end
    end

    ##
    # Gets the width of the display.
    def width
      SCREEN_W
    end

    ##
    # Gets the height of the display.
    def height
      SCREEN_H
    end

    ##
    # Is the display data dirty?
    def dirty?
      @dirty
    end

    ##
    # Low level function to set a single bit.
    def set_bit(x, y, bit = true)
      raise InvalidPosition, "'x' must be between 0 and #{width - 1}" if x < 0 || x >= width
      raise InvalidPosition, "'y' must be between 0 and #{height - 1}" if y < 0 || y >= height
      unless @bitmap[y][x] == bit
        @bitmap[y][x] = bit
        @dirty = true
      end
      self
    end

    ##
    # Low level function to get a single bit.
    def get_bit(x, y)
      raise InvalidPosition, "'x' must be between 0 and #{width - 1}" if x < 0 || x >= width
      raise InvalidPosition, "'y' must be between 0 and #{height - 1}" if y < 0 || y >= height
      @bitmap[y][x]
    end

    ##
    # Clears the screen.
    def clear(bit = false)
      row = [bit] * width
      (0...height).each do |y|
        @bitmap[y] = row.dup
      end
      @dirty = true
      self
    end

    ##
    # Draws a horizontal line.
    def draw_hline(y, start_x, end_x, bit = true)
      raise InvalidPosition, "'y' must be between 0 and #{height - 1}" if y < 0 || y >= height
      (start_x..end_x).each do |x|
        if x >= 0 && x < width
          unless @bitmap[y][x] == bit
            @bitmap[y][x] = bit
            @dirty = true
          end
        end
      end
      self
    end

    ##
    # Draws a vertical line.
    def draw_vline(x, start_y, end_y, bit = true)
      raise InvalidPosition, "'x' must be between 0 and #{width - 1}" if x < 0 || x >= width
      (start_y..end_y).each do |y|
        if y >= 0 && y < height
          unless @bitmap[y][x] == bit
            @bitmap[y][x] = bit
            @dirty = true
          end
        end
      end
      self
    end

    ##
    # Draws a line.
    def draw_line(start_x, start_y, end_x, end_y, bit = true)
      if start_y == end_y
        draw_hline(start_y, start_x, end_x, bit)
      elsif start_x == end_x
        draw_vline(start_x, start_y, end_y, bit)
      else
        # slope
        m = (end_y - start_y).to_f / (end_x - start_x).to_f

        # and y_offset
        b = start_y - (m * start_x)

        (start_x..end_x).each do |x|
          # simple rounding, add 0.5 and trim to an integer.
          y = ((m * x) + b + 0.5).to_i
          if x >= 0 && x <= width && y >= 0 && y <= height
            unless @bitmap[y][x] == bit
              @bitmap[y][x] = bit
              @dirty = true
            end
          end
        end
      end
      self
    end

    ##
    # Draws a rectangle.
    def draw_rect(x1, y1, x2, y2, bit = true)
      draw_hline(y1, x1, x2, bit) if y1 >= 0 && y1 <= height
      draw_hline(y2, x1, x2, bit) if y2 >= 0 && y2 <= height
      draw_vline(x1, y1, y2, bit) if x1 >= 0 && x1 <= width
      draw_vline(x2, y1, y2, bit) if x2 >= 0 && x2 <= width
      self
    end

    ##
    # Opens a connection to the device.
    def open
      raise AlreadyOpen if @handle
      begin
        @handle = @device.open
        @handle.set_configuration(1)
        @handle.detach_kernel_driver(0) if @handle.kernel_driver_active?(0)
        @handle.claim_interface(0)

        reset
      rescue => e
        @handle.close rescue nil
        @handle = nil
        raise e
      end
      self
    end

    ##
    # Is the connection currently open?
    def open?
      !!@handle
    end

    ##
    # Closes the connection to the device.
    def close
      @handle.close if @handle
      @handle = nil
      self
    end

    def reset
      # clear contents.
      clear.paint
      # reset backlight and contrast to defaults.
      set_backlight BACKLIGHT_DEFAULT
      set_contrast CONTRAST_DEFAULT
    end

    ##
    # Sets the backlight level.
    def set_backlight(level = 0xFF)
      level &= 0xFF
      write [OUT_REPORT_LCD_BACKLIGHT, level]
      self
    end

    ##
    # Sets the contrast level.
    def set_contrast(level = 0xFF)
      level &= 0xFF
      write [OUT_REPORT_LCD_CONTRAST, level]
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
            # send the data in two packets for each memory line.
            packet_1 = [OUT_REPORT_CMD_DATA, cs, 0x02, 0x00, 0x00, 0xb8 | line, 0x00, 0x00, 0x40, 0x00, 0x00, 32 ]
            packet_2 = [OUT_REPORT_DATA, cs | 0x01, 0x00, 0x00, 32 ]

            (0..63).each do |index|
              # each byte holds the data for 8 rows.
              byte = 0x00
              (0..7).each do |bit|
                x = (csi * 64) + index
                y = ((line * 8) + bit) % height

                byte |= (1 << bit) if @bitmap[y][x]
              end

              # add the byte to the correct packet.
              (index < 32 ? packet_1 : packet_2) << byte
            end
            # send the packets.
            write packet_1
            write packet_2
          end
        end
        @dirty = false
      end
      self
    end

    ##
    # Sets the callback to be run when a key is pressed or released.
    #
    # Passed the two bytes representing the key states to the block.
    #
    # Returns the previous callback.
    def on_keypress(&block)
      @on_keypress,ret = block,@on_keypress
      ret
    end

    ##
    # Sets the callback to be run when IR data is received.
    #
    # Passes the bytes decoded from the IR data to the block.
    #
    # Returns the previous callback.
    def on_ir(&block)
      @on_ir,ret = block,@on_ir
      ret
    end

    # :nodoc:
    def inspect
      "#<#{self.class.name}:#{self.object_id} device=#{@device.inspect} #{open? ? 'OPEN' : 'CLOSED'}>"
    end

    # :nodoc:
    def self.method_missing(meth, *args, &block)
      # basically allows this class to function as an array as well.
      arr = devices

      if arr.respond_to?(meth)
        arr.send(meth, *args, &block)
      else
        super meth, *args, &block
      end
    end

    ##
    # Gets the manufacturer.
    def manufacturer
      @device.manufacturer
    end

    ##
    # Gets the product.
    def product
      @device.product
    end

    ##
    # Processes any waiting events for the LCD.
    def loop
      input = read(32)
      puts "I just read #{input.inspect}." if input

      if input && input.count > 0
        status = input.delete_at(0)

        case status
          when IN_REPORT_KEY_STATE
            key_data input

          when IN_REPORT_IR_DATA
            ir_data input

          else

        end

      end

      paint
    end


    private

    def key_data(data)
      @key_data ||= []
      if @on_keypress
        if @key_data != data
          @on_keypress.call data
        end
      end
      @key_data = data
    end

    def ir_data(data)
      @ir_data ||= []
      if @on_ir
        if @ir_data != data
          @on_ir.call data
        end
      end
      @ir_data = data
    end

    def initialize(device)
      @device = device
      @handle = nil
      row = [false] * width
      @bitmap = []
      height.times do
        @bitmap << row.dup
      end
      @on_keypress = @on_ir = nil
      @dirty = true
    end

    def write(data)
      raise NotOpen unless @handle

      @handle.interrupt_transfer(
          endpoint: PICOLCD_USB_EP_WRITE,
          dataOut: data.pack('C*'),
          timeout: 1000
      )
    end

    def read(byte_count = 32)
      raise NotOpen unless @handle
      begin
        @handle.interrupt_transfer(
            endpoint: PICOLCD_USB_EP_READ,
            dataIn: byte_count || 32,
            timeout: 50
        )
      rescue LIBUSB::ERROR_TIMEOUT => _
        nil
      end
    end

  end
end