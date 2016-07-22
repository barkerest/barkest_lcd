require 'test/unit'
require './lib/models/pico_lcd_256x64'

class PicoLcd256x64Test < Test::Unit::TestCase

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    devs = ::BarkestLcd::PicoLcd256x64.devices(true)
    @dev = (devs && devs.count > 0) ? devs.first : nil
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  test 'should allow opening/closing' do
    skip unless @dev
    assert !@dev.open?
    @dev.open
    assert @dev.open?
    assert_raise ::BarkestLcd::PicoLcd256x64::AlreadyOpen do
      @dev.open
    end
    @dev.close
    assert !@dev.open?
  end



end