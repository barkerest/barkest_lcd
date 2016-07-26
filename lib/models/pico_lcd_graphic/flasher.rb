
BarkestLcd::PicoLcdGraphic.class_eval do

  init_hook :init_flasher


  ##
  # Delay for commands.
  COMMAND_DELAY     = 0x64


  ##
  # Gets the current mode of the device.
  attr_reader :mode


  ##
  # Is the device currently functioning as a flasher?
  def is_flasher?
    (mode == :flasher)
  end


  ##
  # Switch between keyboard and flasher mode.
  def switch_mode
    next_mode = (mode == :keyboard) ? :flasher : :keyboard
    mode = :switching
    timeout = 2500

    if next_mode == :flasher
      write [ HID_REPORT.EXIT_KEYBOARD, timeout & 0xFF, (timeout >> 8) & 0xFF ]
    else
      write [ HID_REPORT.EXIT_FLASHER, timeout & 0xFF, (timeout >> 8) & 0xFF ]
    end

    while mode == :switching
      sleep 0.01
      loop
      if mode == :switching
        timeout -= 10
        raise BarkestLcd::PicoLcdGraphic::Timeout if timeout < 0
      end
    end

    self
  end


  private


  def init_flasher(_)
    @mode = :keyboard

    input_hook(HID_REPORT.EXIT_FLASHER) do |_,_,data|
      data = data.getbyte(0)
      if data == 0
        @mode = :keyboard
        debug 'switch to KEYBOARD mode'
      else
        @mode = :unknown
        log_error data, 'HID_REPORT.EXIT_FLASHER failed'
      end
    end

    input_hook(HID_REPORT.EXIT_KEYBOARD) do |_,_,data|
      data = data.getbyte(0)
      if data == 0
        @mode = :flasher
        debug 'switched to FLASHER mode'
      else
        @mode = :unknown
        log_error data, 'HID_REPORT.EXIT_KEYBOARD failed'
      end
    end
  end


  def flash_is_enabled?(type)
    if is_flasher?
      return (FLASH_TYPE.keys.include?(type) || FLASH_TYPE.values.include?(type))
    end
    false
  end

  def get_flash_write_message(type)
    if is_flasher?
      return case type
               when :CODE_MEMORY, FLASH_TYPE.CODE_MEMORY
                 FLASH_REPORT.WRITE_MEMORY

               when :CODE_SPLASH, FLASH_TYPE.CODE_SPLASH
                 KEYBD_REPORT.WRITE_MEMORY

               when :EPROM_EXTERNAL, FLASH_TYPE.EPROM_EXTERNAL
                 OUT_REPORT.EXT_EE_WRITE

               when :EPROM_INTERNAL, FLASH_TYPE.EPROM_INTERNAL
                 OUT_REPORT.INT_EE_WRITE

               else
                 0
             end
    end
    0
  end

  def get_flash_read_message(type)
    if is_flasher?
      return case type
               when :CODE_MEMORY, FLASH_TYPE.CODE_MEMORY
                 FLASH_REPORT.READ_MEMORY

               when :CODE_SPLASH, FLASH_TYPE.CODE_SPLASH
                 KEYBD_REPORT.READ_MEMORY

               when :EPROM_EXTERNAL, FLASH_TYPE.EPROM_EXTERNAL
                 OUT_REPORT.EXT_EE_READ

               when :EPROM_INTERNAL, FLASH_TYPE.EPROM_INTERNAL
                 OUT_REPORT.INT_EE_READ

               else
                 0
             end
    end
    0
  end




end