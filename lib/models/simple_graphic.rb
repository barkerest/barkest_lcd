module BarkestLcd
  ##
  # Adds some simple graphics capabilities to a model.
  module SimpleGraphic

    ##
    # An error occurring when an invalid 'x' or 'y' coordinate is specified.
    InvalidPosition = Class.new(StandardError)

    public

    ##
    # Gets the width of the graphic object.
    def width
      @graphic_width ||= 0
    end

    ##
    # Gets the height of the graphic object.
    def height
      @graphic_height ||= 0
    end

    ##
    # Is the graphic object dirty?
    def dirty?
      @graphic_dirty
    end

    ##
    # Low level function to set a single bit.
    def set_bit(x, y, bit = true)
      raise BarkestLcd::SimpleGraphic::InvalidPosition, "'x' must be between 0 and #{width - 1}" if x < 0 || x >= width
      raise BarkestLcd::SimpleGraphic::InvalidPosition, "'y' must be between 0 and #{height - 1}" if y < 0 || y >= height
      unless @graphic_data[y][x] == bit
        @graphic_data[y][x] = bit
        @graphic_dirty      = true
      end
      self
    end

    ##
    # Low level function to get a single bit.
    def get_bit(x, y)
      return false if x < 0 || x >= width
      return false if y < 0 || y >= height
      @graphic_data[y][x]
    end

    ##
    # Clears the screen.
    def clear(bit = false)
      row_data = [bit] * width
      (0...height).each do |y|
        @graphic_data[y] = row_data.dup
      end
      @graphic_dirty = true
      self
    end

    ##
    # Draws a horizontal line.
    def draw_hline(y, start_x, end_x, bit = true)
      raise BarkestLcd::SimpleGraphic::InvalidPosition, "'y' must be between 0 and #{height - 1}" if y < 0 || y >= height
      (start_x..end_x).each do |x|
        if x >= 0 && x < width
          unless @graphic_data[y][x] == bit
            @graphic_data[y][x] = bit
            @graphic_dirty      = true
          end
        end
      end
      self
    end

    ##
    # Draws a vertical line.
    def draw_vline(x, start_y, end_y, bit = true)
      raise BarkestLcd::SimpleGraphic::InvalidPosition, "'x' must be between 0 and #{width - 1}" if x < 0 || x >= width
      (start_y..end_y).each do |y|
        if y >= 0 && y < height
          unless @graphic_data[y][x] == bit
            @graphic_data[y][x] = bit
            @graphic_dirty      = true
          end
        end
      end
      self
    end

    ##
    # Draws a line.
    def draw_line(start_x, start_y, end_x, end_y, bit = true)
      if start_y == end_y
        draw_hline(start_y, start_x, end_x, bit)
      elsif start_x == end_x
        draw_vline(start_x, start_y, end_y, bit)
      else
        # slope
        m = (end_y - start_y).to_f / (end_x - start_x).to_f

        # and y_offset
        b = start_y - (m * start_x)

        (start_x..end_x).each do |x|
          # simple rounding, add 0.5 and trim to an integer.
          x = x.to_i
          y = ((m * x) + b + 0.5).to_i
          if x >= 0 && x < width && y >= 0 && y < height
            unless @graphic_data[y][x] == bit
              @graphic_data[y][x] = bit
              @graphic_dirty      = true
            end
          end
        end
      end
      self
    end

    ##
    # Draws a rectangle.
    def draw_rect(x, y, w, h, bit = true)
      x2 = x + w - 1
      y2 = y + h - 1
      draw_hline(y, x, x2, bit) if y >= 0 && y <= height
      draw_hline(y2, x, x2, bit) if y2 >= 0 && y2 <= height
      draw_vline(x, y, y2, bit) if x >= 0 && x <= width
      draw_vline(x2, y, y2, bit) if x2 >= 0 && x2 <= width
      self
    end



    protected

    def init_graphic(width, height)
      @graphic_width  = width < 4 ? 4 : width
      @graphic_height = height < 4 ? 4 : height
      row_data        = [false] * width
      @graphic_data   = []
      @graphic_height.times { @graphic_data << row_data.dup }
      @graphic_dirty = true
      @graphic_clean_data = nil
    end

    def clear_dirty
      @graphic_dirty          = false
      @graphic_clean_data     = []
      @graphic_height.times { |line| @graphic_clean_data << @graphic_data[line].dup }
    end

    def dirty_rect?(x, y, w, h)
      raise InvalidPosition, "'x' must be between 0 and #{width - 1}" if x < 0 || x >= width
      raise InvalidPosition, "'y' must be between 0 and #{height - 1}" if y < 0 || y >= height
      raise InvalidPosition, "'w' cannot be less than 1" if w < 1
      raise InvalidPosition, "'h' cannot be less than 1" if h < 1
      x2 = x + w - 1
      y2 = y + h - 1
      raise InvalidPosition, "'w' must not be greater than #{width} - 'x'" if x2 >= width
      raise InvalidPosition, "'h' must not be greater than #{height} - 'y'" if y2 >= height

      return true unless @graphic_clean_data

      (y..y2).each do |yy|
        clean_row = @graphic_clean_data[yy]
        test_row = @graphic_data[yy]
        (x..x2).each do |xx|
          return true unless test_row[xx] == clean_row[xx]
        end
      end

      false
    end

  end
end