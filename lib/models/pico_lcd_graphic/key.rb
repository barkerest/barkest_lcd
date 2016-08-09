BarkestLcd::PicoLcdGraphic.class_eval do

  init_hook :init_key


  ##
  # Sets the code to run when a key is pressed down.
  #
  # Yields the key number as a single byte.
  def on_key_down(&block)
    raise ArgumentError, 'Missing block.' unless block_given?
    @on_key_down = block
    self
  end


  ##
  # Sets the code to run when a key is released.
  #
  # Yields the key number as a single byte.
  def on_key_up(&block)
    raise ArgumentError, 'Missing block.' unless block_given?
    @on_key_up = block
    self
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


  def init_key(_)
    @keys = []
    @on_key_up = @on_key_down = nil

    # Hook the keyboard and IR data events.
    input_hook IN_REPORT.KEY_STATE do |_, _, data|
      if data.length < 2
        log_error 2, 'not enough data for IN_REPORT.KEY_STATE'
      else
        process_key_state data
      end
    end
  end


  def process_key_state(data)
    key1 = data.length >= 1 ? (data.getbyte(0) & 0xFF) : 0
    key2 = data.length >= 2 ? (data.getbyte(1) & 0xFF) : 0

    # make sure the array is big enough to represent the largest reported key.
    max = (key1 < key2 ? key2 : key1) + 1
    if @keys.length < max
      @keys += [nil] * (max - @keys.length)
    end

    HIDAPI.debug "Pressed keys: #{key1} #{key2}"

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

end

