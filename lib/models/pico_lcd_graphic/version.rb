BarkestLcd::PicoLcdGraphic.class_eval do

  init_hook :init_version

  ##
  # Gets the version of this device.
  def version(refresh = false)
    @version = nil if refresh

    unless @version
      @version = []
      write [ HID_REPORT.GET_VERSION_1 ]
      loop while @version.empty?
    end

    @version
  end

  private

  def process_version(type, data)
    if data.length < 2
      log_error 2, "not enough data for HID_REPORT.#{HID_REPORT.key(type)}"
      @version[0] = 0
      @version[1] = 0
    else
      @version[0] = data.getbyte(1)
      @version[1] = data.getbyte(0)
    end
  end

  def init_version(_)
    @version = nil
    input_hook(HID_REPORT.GET_VERSION_1) do |_,type,data|
      process_version(type, data)
    end
  end


end