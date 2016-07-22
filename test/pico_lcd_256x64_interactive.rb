require './lib/models/pico_lcd_256x64'

class SampleApp

  def self.ask(question)
    print question
    result = STDIN.gets.to_s.strip.upcase[0]
    result == 'Y'
  end

  def self.run
    dev_list = BarkestLcd::PicoLcd256x64.devices(true)

    raise 'No picLCD 256x64 devices found.' unless dev_list && dev_list.count > 0

    @dev = dev_list.first

    @dev.open

    raise 'Could not open.' unless @dev.open?

    begin
      @dev.on_keypress do |(low,high)|
        if low == 0 && high == 0
          puts 'No key is pressed.'
        else
          puts "Key \\#{low.to_s(16).lpad(2,'0')}\\#{high.to_s(16).lpad(2,'0')} is pressed."
        end
      end

      @dev.clear.paint
      raise 'Screen should be empty.' unless ask('Is the screen empty?')
      @dev.clear(true).paint
      raise 'Screen should be full.' unless ask('Is the screen full?')

      @dev.clear
      @dev.width.times do |x|
        @dev.draw_vline(x, 0, @dev.height) if x.odd?
      end
      @dev.paint
      raise 'Screen should have vertical lines.' unless ask('Does the screen have vertical lines on it?')

      @dev.clear
      @dev.height.times do |y|
        @dev.draw_hline(y, 0, @dev.width) if y.even?
      end
      @dev.set_contrast(BarkestLcd::PicoLcd256x64::CONTRAST_DEFAULT + 10).paint
      raise 'Screen should have horizontal lines.' unless ask('Does the screen have horizontal lines on it?')
      @dev.set_contrast(BarkestLcd::PicoLcd256x64::CONTRAST_DEFAULT)

      if ask('Does the screen have buttons?')
        while true
          print 'Press the key you want to test.'

          while true
            @dev.loop
            print '.'
          end

        end
      end

      @dev.clear.paint
    ensure
      @dev.close
    end

    puts 'Tests complete.'
  end
end

SampleApp.run