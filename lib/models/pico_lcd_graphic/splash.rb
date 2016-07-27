BarkestLcd::PicoLcdGraphic.class_eval do

  init_hook :init_splash

  ##
  # Gets the size for the splash storage.
  def splash_size(refresh = false)
    @splash_size = nil if refresh

    if @splash_size.nil?
      write [ HID_REPORT.GET_MAX_STX_SIZE ]
      loop_while { @splash_size.nil? }
    end

    { size: @splash_size, max: @splash_max_size }
  end



  private

  def init_splash(_)
    @splash_size = nil
    @splash_max_size = nil

    input_hook(HID_REPORT.GET_MAX_STX_SIZE) do |_,_,data|
      if data.length < 4
        @splash_size = 0
        @splash_max_size = 0
        log_error 2, 'not enough data for HID_REPORT.GET_MAX_STX_SIZE'
      else
        @splash_max_size = ((data.getbyte(1) << 8) & 0xFF00) | (data.getbyte(0) & 0xFF)
        @splash_size = ((data.getbyte(3) << 8) & 0xFF00) | (data.getbyte(2) & 0xFF)
        debug "splash size=#{@splash_size}, max=#{@splash_max_size}"
      end
    end

  end

end