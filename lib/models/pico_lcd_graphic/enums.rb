require 'models/hash_enum'

BarkestLcd::PicoLcdGraphic.class_eval do

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


  ##
  # Types for flash operations.
  FLASH_TYPE = BarkestLcd::HashEnum.new(
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
      ERROR:            0x10,
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

end