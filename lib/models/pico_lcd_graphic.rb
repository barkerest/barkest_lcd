
require 'models/simple_debug'

module BarkestLcd
  ##
  # A class to interface with the picoLCD 256x64 (aka picoLCD Graphic) from [www.mini-box.com](http://www.mini-box.com).
  class PicoLcdGraphic

    include BarkestLcd::SimpleDebug



    ##
    # Any of the Pico LCD errors.
    PicoLcdError = Class.new(StandardError)

    ##
    # The device has already been opened.
    AlreadyOpen = Class.new(PicoLcdError)

    ##
    # The device is not currently open.
    NotOpen = Class.new(PicoLcdError)

    ##
    # The operation has timed out.
    Timeout = Class.new(PicoLcdError)



    ##
    # Gets the manufacturer name.
    attr_reader :manufacturer

    ##
    # Gets the product name.
    attr_reader :product

    ##
    # Gets the serial number.
    attr_reader :serial

    ##
    # Gets the path.
    attr_reader :path



    ##
    # USB Vendor ID
    VENDOR_ID     = 0x04d8

    ##
    # USB Device ID
    DEVICE_ID     = 0xc002



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

      self
    end


    ##
    # Processes any waiting input from the device and paints the screen if it is dirty.
    def loop
      data = read
      if data && data.length > 0

        type = data.getbyte(0)
        data = data[1..-1]

        input_hook(type).call(self, type, data)

      end
      loop_hook.each { |block| block.call(self) }
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


    # :nodoc:
    def to_s
      inspect
    end


    protected


    ##
    # Hooks a block to run for a specific incoming type.
    #
    # Yields the device instance, type code, and the data to the block.
    def input_hook(incoming_type, method_name = nil, &block)
      @input_hook ||= {}

      if block_given?
        # set the hook.
        @input_hook[incoming_type] = block
      elsif method_name
        @input_hook[incoming_type] = Proc.new { |dev, type, data| dev.send(method_name, dev, type, data) }
      else
        # get the hook
        @input_hook[incoming_type] ||= Proc.new { |dev, type, data| debug "no input hook for #{type} message type with #{data.length} bytes of data" }
      end
    end


    ##
    # Hooks a block to run during the loop method.
    #
    # Yields the device instance.
    def loop_hook(method_name = nil, &block)
      @loop_hook ||= []
      if block_given?
        @loop_hook << block
      elsif method_name
        @loop_hook << Proc.new { |dev| dev.send(method_name, dev) }
      end
      @loop_hook
    end


    ##
    # Hooks a block to run during initialization of an instance.
    #
    # Yields the device instance.
    def self.init_hook(method_name = nil, &block)
      @init_hook ||= []
      if block_given?
        @init_hook << block
      elsif method_name
        @init_hook << Proc.new { |dev| dev.send(method_name, dev) }
      end
      @init_hook
    end


    private


    def initialize(hid_device)
      @path = hid_device.path
      @manufacturer = hid_device.manufacturer_string
      @product = hid_device.product_string
      @serial = hid_device.serial_number
      @device = nil

      self.class.init_hook.each do |init_proc|
        init_proc.call self
      end
    end


    def write(data)
      raise NotOpen unless @device
      @device.write(data.pack('C*'))
    end


    def read
      raise NotOpen unless @device
      @device.read(32)
    end

  end
end

Dir.glob(File.expand_path('../pico_lcd_graphic/*.rb', __FILE__)).each do |file|
  require file
end