require 'models/font'

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
    # Gets a snapshot of the graphic data.
    def graphic_data_snapshot(x = nil, y = nil, w = nil, h = nil)
      if x.nil? && y.nil? && w.nil? && h.nil?
        return @graphic_data.map{|row| row.dup.freeze}.freeze
      end

      x ||= 0
      y ||= 0
      w ||= width - x
      h ||= height - y

      return [] if h < 1
      return [ [] * h ] if w < 1

      ret = []
      row = [ false ] * w
      h.times { ret << row.dup }

      y2 = y + h - 1
      x2 = x + w - 1
      (y..y2).each do |source_y|
        if source_y >= 0 && source_y < height
          dest_y  = source_y - y
          dest_row = ret[dest_y]
          source_row = @graphic_data[source_y]
          (x..x2).each do |source_x|
            if source_x >= 0 && source_x < width
              dest_x = source_x - x
              dest_row[dest_x] = source_row[source_x]
            end
          end
        end
      end

      ret.map{|r| r.freeze}.freeze
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
      row = @graphic_data[y]
      (start_x..end_x).each do |x|
        if x >= 0 && x < width
          unless row[x] == bit
            row[x]              = bit
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
      raise ArgumentError, '\'w\' must be at least 1' if w < 1
      raise ArgumentError, '\'h\' must be at least 1' if h < 1
      x2 = x + w - 1
      y2 = y + h - 1
      draw_hline(y, x, x2, bit) if y >= 0 && y <= height
      draw_hline(y2, x, x2, bit) if y2 >= 0 && y2 <= height
      draw_vline(x, y, y2, bit) if x >= 0 && x <= width
      draw_vline(x2, y, y2, bit) if x2 >= 0 && x2 <= width
      self
    end

    ##
    # Draws a filled rectangle.
    def fill_rect(x, y, w, h, bit = true)
      raise ArgumentError, '\'w\' must be at least 1' if w < 1
      raise ArgumentError, '\'h\' must be at least 1' if h < 1
      x2 = x + w - 1
      y2 = y + h - 1
      (y..y2).each do |dest_y|
        if dest_y >= 0 && dest_y < height
          dest_row = @graphic_data[dest_y]
          (x..x2).each do |dest_x|
            if dest_x >= 0 && dest_x < width
              unless dest_row[dest_x] == bit
                dest_row[dest_x]  = bit
                @graphic_dirty    = true
              end
            end
          end
        end
      end
      self
    end

    ##
    # Copies data directly to the graphic.
    #
    # The +data+ parameter is special and can follow one of two paths.
    #
    # If no block is provided, then +data+ must be a two dimensional array of boolean or integers.
    #
    # If a block is provided, then +data+ is passed to the block as the third parameter.  If +data+ is nil
    # then the third parameter is nil.  The block will receive the current x and y offset as the first two
    # parameters.  The block must return a boolean value, true to set a pixel or false to clear it.  It can
    # also return nil to leave a pixel as is.
    #
    # :yields: +offset_x+, +offset_y+, and +data+ to the block which must return a boolean.
    #
    #   blit(10, 10, 20, 5, my_data) do |offset_x, offset_y, data|
    #     # offset_x will be in the range (0...20)
    #     # offset_y will be in the range (0...5)
    #     data.is_pixel_set?(offset_x, offset_y)
    #   end
    #
    def blit(x, y, w, h, data = nil, &block)
      raise ArgumentError, 'data is required unless a block is provided' if data.nil? && !block_given?
      raise ArgumentError, '\'w\' must be at least 1' if w < 1
      raise ArgumentError, '\'h\' must be at least 1' if h < 1

      x2 = x + w - 1
      y2 = y + h - 1

      # The default block simply looks up the bit in the data and returns true if the bit is true or 1.
      unless block_given?
        block = Proc.new do |b_x, b_y, b_data|
          b_bit = b_data[b_y][b_x]
          b_bit == true || b_bit == 1
        end
      end

      (y..y2).each do |dest_y|
        if dest_y >= 0 && dest_y < height
          dest_row = @graphic_data[dest_y]
          (x..x2).each do |dest_x|
            if dest_x >= 0 && dest_x < width
              offset_x = dest_x - x
              offset_y = dest_y - y
              bit = block.call(offset_x, offset_y, data)
              unless bit.nil?
                unless dest_row[dest_x] == bit
                  dest_row[dest_x]  = bit
                  @graphic_dirty    = true
                end
              end
            end
          end
        end
      end

      self
    end

    ##
    # Attribute used to store the horizontal text offset after the last call to draw_text.
    attr_accessor :text_offset_left

    ##
    # Attribute used to store the vertical text offset after the last call to draw_text.
    attr_accessor :text_offset_bottom

    ##
    # Draws a string of text to the graphic.
    #
    # The text will not wrap.
    #
    # Options:
    # *   x - The horizontal position for the text.  Defaults to +text_offset_left+.
    # *   y - The vertical position for the text.  Defaults to aligning the bottom with +text_offset_bottom+.
    # *   bold - Defaults to false.
    # *   bit - Defaults to true.
    def draw_text(text, options = {})

      if text.include?("\n")
        if options[:y]
          self.text_offset_bottom = options[:y]
        else
          font = options[:bold] ? BarkestLcd::Font.bold : BarkestLcd::Font.regular
          self.text_offset_bottom = text_offset_bottom ? (text_offset_bottom - font.height) : 0
        end
        options[:x] ||= (text_offset_left || 0)
        text.split("\n").each do |line|
          draw_text(line, options.merge( { y: text_offset_bottom }))
        end
        return self
      end

      x = options.delete(:x)
      y = options.delete(:y)

      bold = options.delete(:bold)
      bold = false if bold.nil?
      bit = options.delete(:bit)
      bit = true if bit.nil?
      char_spacing = options.delete(:char_spacing) || -1

      font = bold ? BarkestLcd::Font.bold : BarkestLcd::Font.regular

      max_h = font.height

      x ||= text_offset_left || 0

      # we'll be aligning the bottoms of the glyphs.
      if y
        bottom = y + max_h
      else
        bottom = text_offset_bottom || max_h
      end

      # store the bottom offset and left offset for future use.
      self.text_offset_bottom = bottom
      self.text_offset_left = x

      text = text.to_s
      return self if text == ''

      glyphs = font.glyphs(text)

      glyphs.each do |glyph|
        if x > width # no need to continue.
          # update the left offset.
          self.text_offset_left = x
          return self
        end
        if glyph.width > 0 && glyph.height > 0
          y = bottom - glyph.height
          blit(x, y, glyph.width, glyph.height, glyph.data) { |_x, _y, _data| _data[_y][_x] ? bit : nil }
        end
        x += glyph.width > 0 ? (glyph.width + char_spacing) : 0
      end

      # update the left offset.
      self.text_offset_left = x

      self
    end

    ##
    # Draws a string of text to a confined region of the graphic.
    #
    # Options:
    # *   bold - Defaults to false.
    # *   bit - Defaults to true.
    # *   align - Can be :left, :center, or :right. Defaults to :left.
    # *   border - Defaults to false.
    # *   fill - Defaults to false.
    #
    def draw_text_box(text, x, y, w, h, options = {})
      bold = options.delete(:bold)
      bold = false if bold.nil?
      bit = options.delete(:bit)
      bit = true if bit.nil?
      align = options.delete(:align)
      align = :left if align.nil?
      border = options.delete(:border)
      border = false if border.nil?
      fill = options.delete(:fill)
      fill = false if fill.nil?
      char_spacing = options.delete(:char_spacing) || -1

      raise ArgumentError, '\'w\' must be at least 1' if w < 1
      raise ArgumentError, '\'h\' must be at least 1' if h < 1

      if fill
        fill_rect(x, y, w, h, !bit)
      end

      if border && w > 2
        x2 = x + w - 1
        draw_vline(x, y, y + h - 1, bit) if x >= 0 && x < width
        draw_vline(x2, y, y + h - 1, bit) if x2 >= 0 && x2 < width
        w -= 2
        x += 1
      end

      if border && h > 2
        y2 = y + h - 1
        draw_hline(y, x, x + w - 1, bit) if y >= 0 && y < height
        draw_hline(y2, x, x + w - 1, bit) if y2 >= 0 && y2 < height
        h -= 2
        y += 1
      end

      text = text.to_s
      return self if text == ''

      # We'll use an anonymous class to buffer the text box.
      box = Class.new do
        include BarkestLcd::SimpleGraphic
        def initialize(w,h)
          init_graphic w, h
        end
      end.new(w, h)

      # copy the current contents of the area into the box.
      box.blit(0, 0, w, h, graphic_data_snapshot(x, y, w, h))

      font = bold ? BarkestLcd::Font.bold : BarkestLcd::Font.regular

      # measure the text and split it into lines, grab the lines, ignore the size.
      text_lines = font.measure(text, w)[2]

      text_lines.each do |line|
        lx = 0
        if align == :center
          lw = font.measure(line)[0]
          lx = (w - lw) / 2
        elsif align == :right
          lw = font.measure(line)[0]
          lx = (w - lw)
        end
        # each line uses the bottom offset from the previous line as the top of the current line.
        box.draw_text(line, x: lx, y: box.text_offset_bottom, bold: bold, bit: bit, char_spacing: char_spacing)
        break if box.text_offset_bottom > h
      end

      # copy the contents of the box back into the current graphic.
      blit(x, y, w, h, box.graphic_data_snapshot)

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