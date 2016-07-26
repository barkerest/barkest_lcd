BarkestLcd::PicoLcdGraphic.class_eval do

  init_hook :init_ir

  ##
  # Sets the code to run when IR data is received.
  #
  # Yields the bytes received as a string.
  def on_ir_data(&block)
    raise ArgumentError, 'Missing block.' unless block_given?
    @on_ir_data = block
    self
  end

  private

  def init_ir(_)
    @on_ir_data = nil
    input_hook IN_REPORT.IR_DATA do |_, _, data|
      process_ir_data data
    end
  end

  def process_ir_data(data)
    debug "IR data: #{data.inspect}"
    if @on_ir_data
      @on_ir_data.call(data)
    end
  end

end