module BarkestLcd
  ##
  # A basic bitmap font.
  class Font

    ##
    # Gets or sets the name of this font.
    attr_accessor :name

    ##
    # Gets or sets the size of this font.
    attr_accessor :size

    ##
    # Gets or sets the bold flag.
    attr_accessor :bold

    ##
    # Creates a new bitmap font from a hash.
    #
    #   glyphs = {
    #       :name => "Font Name",   # optional
    #       :size => 8,             # optional
    #       :bold => false,         # optional
    #       97 => {               # ASCII character code.
    #           :char => "a",     # printed character.
    #           :width => 8,      # width in pixels
    #           :height => 8,     # height in pixels
    #           :data => [        # array containing row data.
    #               "        ",   # rows may be strings or arrays.
    #               "        ",   # when strings, non-space characters are set pixels.
    #               "   **   ",   # when arrays, values of true or 1 are set pixels.
    #               "     *  ",
    #               "  ****  ",
    #               " *   *  ",
    #               "  ****  ",
    #               "        ",
    #           ],
    #       },
    #       ...
    #   }
    def initialize(glyphs)
      raise ArgumentError unless glyphs.is_a?(Hash)

      @name = glyphs.delete(:name) || 'Font'
      @size = glyphs.delete(:size) || 8
      @bold = glyphs.delete(:bold) || false
      @glyphs = {}

      glyphs.each do |k,v|
        k = k.to_i
        raise ArgumentError, 'hash must have numeric keys greater than or equal to 32 and less than 127' if k < 32 || k > 127
        raise ArgumentError, 'hash must have hashes as values' unless v.is_a?(Hash)
        raise ArgumentError, 'hash values must have a :char key' unless v[:char]
        raise ArgumentError, 'hash values must have a :width key' unless v[:width]
        raise ArgumentError, 'hash values must have a :height key' unless v[:height]
        raise ArgumentError, 'hash values must have a :data key' unless v[:data]
        raise ArgumentError, 'hash :data key must have an array value' unless v[:data].is_a?(Array)

        glyph = {
            char: v[:char].to_s.freeze,
            width: v[:width].to_i.freeze,
            height: v[:height].to_i.freeze,
            data: []
        }

        raise ArgumentError, 'hash :data value must have exactly :height members' unless v[:data].length == glyph[:height]
        v[:data].each_with_index do |row, row_index|
          raise ArgumentError, 'hash :data value members must be arrays or strings' unless row.is_a?(Array) || row.is_a?(String)
          raise ArgumentError, 'hash :data value members must have :width values' unless row.length == glyph[:width]

          glyph[:data][row_index] = [ false ] * glyph[:width]
          if row.is_a?(String)
            row.chars.each_with_index do |ch, ch_index|
              glyph[:data][row_index][ch_index] = true unless ch == ' '   # spaces are false, everything else is true.
            end
          else
            row.each_with_index do |bit, bit_index|
              glyph[:data][row_index][bit_index] = true if bit == true || bit == 1
            end
          end
          glyph[:data][row_index].freeze

        end

        def glyph.char
          self[:char]
        end
        def glyph.width
          self[:width]
        end
        def glyph.height
          self[:height]
        end
        def glyph.data
          self[:data]
        end

        glyph[:data].freeze

        glyph.freeze

        @glyphs[k] = glyph
      end

    end

    ##
    # Gets a glyph for the specified character.
    #
    # +char+ should be a string containing the character.
    def glyph(char)
      char = char.to_s
      ch = char.getbyte(0).to_i
      @glyphs[ch] ||= {
          char: char,
          width: 0,
          height: 0,
          data: []
      }
    end

    ##
    # Gets the glyphs to draw the specified string with.
    def glyphs(string)
      string.to_s.chars.map { |char| glyph(char) }
    end

    ##
    # Measures the specified string.
    #
    # If you supply a +max_width+ it will try to fit the string into the specified width.
    #
    # With a +max_width+ it returns [ width, height, lines ].
    # Without a +max_width+ it returns [ width, height ].
    def measure(string, max_width = -1)
      if max_width > 0
        w,h = measure(string, -1)
        if w <= max_width
          return [w, h, [ string ]]
        else
          # wrap on words.
          cur_line,_,next_line = string.rpartition(' ')

          return [ w, h, [ string ] ] unless next_line  # no spaces to wrap on.
          while true
            w, h = measure(cur_line)
            cur,_,next_word = cur_line.rpartition(' ')
            if w <= max_width || next_word.nil?
              w2, h2, lines = measure(next_line, max_width)
              w = w2 if w2 > w
              h += h2
              return [ w, h, [ cur_line ] + lines ]
            end
            next_line = next_word + ' ' + next_line
            cur_line = cur
          end
        end
      else
        w, h = 0, 0
        glyphs(string).each do |g|
          h = g[:height] if g[:height] > h
          w += g[:width]
        end
        [w, h]
      end
    end

    ##
    # Generates a hash that can be loaded into a font.
    def inspect(formatted = false)
      ret = '{'
      ret += "\n  " if formatted
      ret += ":name => #{name.inspect},"
      ret += "\n  " if formatted
      ret += ":size => #{size.inspect},"
      ret += "\n  " if formatted
      ret += ":bold => #{bold.inspect},"
      ret += "\n  " if formatted
      @glyphs.each do |key, glyph|
        ret += "#{key.inspect} => {"
        ret += "\n    " if formatted
        ret += ":char => #{glyph[:char].inspect},"
        ret += "\n    " if formatted
        ret += ":width => #{glyph[:width].inspect},"
        ret += "\n    " if formatted
        ret += ":height => #{glyph[:height].inspect},"
        ret += "\n    " if formatted
        ret += ':data => ['
        ret += "\n      " if formatted
        glyph[:data].each do |row|
          ret += "#{row.map{|bit| bit ? '#' : ' '}.join('').inspect},"
          ret += "\n      " if formatted
        end
        ret = ret.rstrip + "\n    " if formatted
        ret += '],'
        ret += "\n  " if formatted
        ret += '},'
        ret += "\n  " if formatted
      end
      ret = ret.rstrip + "\n" if formatted
      ret + '}'
    end

    def to_s # :nodoc:
      "#<#{self.class.name}:0x#{self.object_id.to_s(16)} name=#{name.inspect} size=#{size.inspect} bold=#{bold.inspect}>"
    end

    ##
    # Attempts to load and process a font.
    #
    # Returns  a Font on success, or nil on failure.
    #
    # There is a possibility that it will load an incorrect font.
    #
    # REQUIRES: rmagick
    #
    # Since the BarkestLcd gem doesn't require 'rmagick', this will always return false by default.
    # If your application includes the 'rmagick' gem, then you can create fonts.  Or you can use an
    # IRB console to create fonts.
    #
    # The created fonts should be stored as a ruby object.  The constants defined in the BarkestLcd::Font class
    # were created in this manner.
    def self.create(font_name = 'Helvetica', size = 8, bold = false)
      return nil if font_name.to_s == ''
      return nil if size < 4 || size > 144

      begin
        require 'rmagick'

        max_black = (Magick::QuantumRange * 0.5).to_i

        img = Magick::Image.new(200,200)

        def img.char_width
          get_pixels(0, 0, columns, 1).each_with_index do |px, x|
            return x if px.to_color == 'magenta'
          end
          nil
        end

        def img.char_height
          get_pixels(0, 0, 1, rows).each_with_index do |px, y|
            return y if px.to_color == 'magenta'
          end
          nil
        end

        img.background_color = 'magenta'
        img.erase!

        draw = Magick::Draw.new
        draw.font = font_name
        draw.font_weight bold ? 'bold' : 'normal'
        draw.pointsize = size
        draw.gravity = Magick::NorthWestGravity
        draw.text_antialias = false
        draw.fill = 'black'
        draw.undercolor = 'white'
        draw.stroke = 'transparent'

        font = {
            name: font_name,
            size: size,
            bold: !!bold,
        }

        " 0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ(){}[]<>`~!@#$%^&*-_=+\\|;:'\",./?".chars.each do |ch|

          glyph = {
              char: ch
          }

          char_code = ch.getbyte(0)

          ch = "\\\\" if ch == "\\"
          ch = "\\\"" if ch == "\""

          img.erase!
          draw.annotate img, 0, 0, 0, 0, ch

          width = img.char_width
          height = img.char_height

          if width.nil?
            puts "Error on char #{ch.inspect}: no width"
          elsif height.nil?
            puts "Error on char #{ch.inspect}: no height"
          else
            glyph[:width] = width
            glyph[:height] = height
            glyph[:data] = []

            img.get_pixels(0, 0, width, height).each_with_index do |px, index|
              x = (index % width).to_i
              y = (index / width).to_i

              glyph[:data][y] ||= []
              glyph[:data][y][x] = px.intensity <= max_black
            end

            font[char_code] = glyph
          end

        end

        Font.new(font)
      rescue LoadError
        nil
      end
    end


  end
end


# Include the components of the model.
Dir.glob(File.expand_path('../font/*.rb', __FILE__)).each do |file|
  require file
end
