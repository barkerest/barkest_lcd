
require 'models/simple_graphic'
require 'models/hash_enum'

module BarkestLcd
  ##
  # A class to interface with the picoLCD 256x64 (aka picoLCD Graphic) from [www.mini-box.com](http://www.mini-box.com).
  class PicoLcdGraphic

    include BarkestLcd::SimpleGraphic

    ##
    # Any of the Pico LCD errors.
    PicoLcdError = Class.new(StandardError)

    ##
    # The device has already been opened.
    AlreadyOpen = Class.new(PicoLcdError)

    ##
    # The device is not currently open.
    NotOpen = Class.new(PicoLcdError)

    attr_reader :manufacturer, :product, :serial, :path, :device

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

    ##
    # Default contrast for the screen.
    DEFAULT_CONTRAST  = 0xE5

    ##
    # Default brightness for the screen.
    DEFAULT_BACKLIGHT = 0x7F

    ##
    # Delay for commands.
    COMMAND_DELAY     = 0x64

    ##
    # Status codes that may be returned from the device.
    STATUS = BarkestLcd::HashEnum.new(
        OK:             0x00,
        ERASE:          0x01,
        WRITE:          0x02,
        READ:           0x03,
        ERROR:          0xFF,
        KEY:            0x10,
        IR:             0x11,
        VER:            0x12,
        DISCONNECTED:   0x13,
    )

    ##
    # Reports received from the device.
    IN_REPORT = BarkestLcd::HashEnum.new(
        POWER_STATE:    0x01,
        KEY_STATE:      0x11,
        IR_DATA:        0x21,
        EXT_EE_DATA:    0x31,
        INT_EE_DATA:    0x32,
    )

    ##
    # Reports sent to the device.
    OUT_REPORT = BarkestLcd::HashEnum.new(
        LED_STATE:      0x81,
        LCD_BACKLIGHT:  0x91,
        LCD_CONTRAST:   0x92,
        CMD:            0x94,
        DATA:           0x95,
        CMD_DATA:       0x96,
        LCD_RESET:      0x93,
        RELAY_ONOFF:    0xB1,
        TESTSPLASH:     0xC1,
        EXT_EE_READ:    0xA1,
        EXT_EE_WRITE:   0xA2,
        INT_EE_READ:    0xA3,
        INT_EE_WRITE:   0xA4,
    )

    ##
    # Splash IDs.
    ID_SPLASH = BarkestLcd::HashEnum.new(
        TIMER:          0x72,
        CYCLE_START:    0x72,
        CYCLE_END:      0x73,
    )


    TYPE = BarkestLcd::HashEnum.new(
        CODE_MEMORY:    0x00,
        EPROM_EXTERNAL: 0x01,
        EPROM_INTERNAL: 0x02,
        CODE_SPLASH:    0x03,
    )

    ##
    # HID reports for device.
    HID_REPORT = BarkestLcd::HashEnum.new(
        GET_VERSION_1:    0xF1,
        GET_VERSION_2:    0xF7,
        GET_MAX_STX_SIZE: 0xF6,
        EXIT_FLASHER:     0xFF,
        EXIT_KEYBOARD:    0xEF,
        SET_SNOOZE_TIME:  0xF8,

    )

    ##
    # Flash reports for the device.
    FLASH_REPORT = BarkestLcd::HashEnum.new(
        ERASE_MEMORY:   0xF2,
        READ_MEMORY:    0xF3,
        WRITE_MEMORY:   0xF4,
    )

    ##
    # Keyboard reports for the device.
    KEYBD_REPORT = BarkestLcd::HashEnum.new(
        ERASE_MEMORY:   0xB2,
        READ_MEMORY:    0xB3,
        WRITE_MEMORY:   0xB4,
        MEMORY:         0x41,
    )

    ##
    # Request results.
    RESULT = BarkestLcd::HashEnum.new(
        OK:                 0x00,
        PARAM_MISSING:      0x01,
        DATA_MISSING:       0x02,
        BLOCK_READ_ONLY:    0x03,
        BLOCK_NOT_ERASABLE: 0x04,
        BLOCK_TOO_BIG:      0x05,
        SECTION_OVERFLOW:   0x06,

    )


    ##
    # Enumerates the picoLCD devices attached to the system.
    def self.devices(refresh = false)
      @devices = nil if refresh
      @devices ||=
          HidApi::hid_enumerate(VENDOR_ID, DEVICE_ID).map do |dev|
            BarkestLcd::PicoLcdGraphic.new(dev)
          end
    end


    ##
    # Is this device currently open?
    def open?
      !!@device
    end


    ##
    # Closes this device.
    def close
      @device.close rescue nil if @device
      @device = nil
      self
    end


    ##
    # Opens this device.
    def open
      raise AlreadyOpen if @device
      @device = HidApi::hid_open_path(path)
      @device.set_nonblocking(1)
      reset
      self
    end


    ##
    # Resets the device.
    def reset
      write [ OUT_REPORT.LCD_RESET, 0x01, 0x00 ]

      (0...4).each do |csi|
        cs = (csi << 2) & 0xFF
        write [ OUT_REPORT.CMD, cs, 0x02, 0x00, 0x64, 0x3F, 0x00, 0x64, 0xC0 ]
      end

      clear.paint
      contrast DEFAULT_CONTRAST
      backlight DEFAULT_BACKLIGHT

      self
    end


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


    # :nodoc:
    def self.method_missing(meth, *args, &block)
      # pass through methods like 'first', 'count', 'each', etc to the 'devices' list.
      list = devices
      if list.respond_to?(meth)
        list.send meth, *args, &block
      else
        super meth, *args, &block
      end
    end


    # :nodoc:
    def inspect
      "#<#{self.class.name}:#{self.object_id} path=#{path.inspect} manufacturer=#{manufacturer.inspect} product=#{product.inspect} (#{open? ? 'OPEN' : 'CLOSED'})>"
    end


    ##
    # Processes any waiting input from the device and paints the screen if it is dirty.
    def loop
      data = read
      if data && data.length > 0
        in_report = data.getbyte(0)
        if in_report == IN_REPORT.KEY_STATE
          process_key_state data[1..-1]
        elsif in_report == IN_REPORT.IR_DATA
          process_ir_data data[1..-1]
        end
      end
      paint
    end


    ##
    # Sets the code to run when a key is pressed down.
    #
    # Yields the key number as a single byte.
    def on_key_down(&block)
      raise ArgumentError, 'Missing block.' unless block_given?
      @on_key_down,ret = block,@on_key_down
      ret
    end


    ##
    # Sets the code to run when a key is released.
    #
    # Yields the key number as a single byte.
    def on_key_up(&block)
      raise ArgumentError, 'Missing block.' unless block_given?
      @on_key_up,ret = block,@on_key_up
      ret
    end


    ##
    # Sets the code to run when IR data is received.
    #
    # Yields the bytes received as a string.
    def on_ir_data(&block)
      raise ArgumentError, 'Missing block.' unless block_given?
      @on_ir_data,ret = block,@on_ir_data
      ret
    end


    ##
    # Gets the state of a specific key.
    def key_state(key)
      return false unless key
      return false if key <= 0
      return false if @keys.length <= key
      @keys[key]
    end


    private


    def initialize(hid_device)
      @path = hid_device.path
      @manufacturer = hid_device.manufacturer_string
      @product = hid_device.product_string
      @serial = hid_device.serial_number
      @device = nil
      init_graphic SCREEN_W, SCREEN_H
      @on_key_up = @on_key_down = @on_ir_data = nil
      @keys = []
    end


    def write(data)
      raise NotOpen unless @device
      @device.write(data.pack('C*'))
    end


    def read
      raise NotOpen unless @device
      @device.read(32)
    end


    def process_key_state(data)
      key1 = data.length >= 1 ? (data.getbyte(0) & 0xFF) : 0
      key2 = data.length >= 2 ? (data.getbyte(1) & 0xFF) : 0

      # make sure the array is big enough to represent the largest reported key.
      max = (key1 < key2 ? key2 : key1) + 1
      if @keys.length < max
        @keys += [nil] * (max - @keys.length)
      end

      # go through the array and process changes.
      @keys.each_with_index do |state,index|
        unless index == 0
          if state && key1 != index && key2 != index
            # key was pressed but is not one of the currently pressed keys.
            if @on_key_up
              @on_key_up.call(index)
            end
            @keys[index] = false
          end
          if key1 == index || key2 == index
            unless state
              # key was not pressed before but is one of the currently pressed keys.
              if @on_key_down
                @on_key_down.call(index)
              end
              @keys[index] = true
            end
          end
        end
      end
    end


    def process_ir_data(data)
      if @on_ir_data
        @on_ir_data.call(data)
      end
    end

  end
end
