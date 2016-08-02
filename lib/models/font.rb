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

        add_glyph_helpers_to glyph

        glyph[:data].freeze

        glyph.freeze

        @glyphs[k] = glyph
      end

      @height = @glyphs.inject(0) { |h,(key,g)| g.height > h ? g.height : h }
      @nil_glyph = add_glyph_helpers_to(
          {
              char: '',
              width: 0,
              height: 0,
              data: []
          }
      ).freeze
    end


    ##
    # Gets the height of the font.
    attr_reader :height

    ##
    # Gets a glyph for the specified character.
    #
    # +char+ should be a string containing the character.
    #
    # Glyphs are hashes that also include helper methods.
    #
    #   g = {
    #     char: ' ',
    #     width: 2,
    #     height: 8,
    #     data: [[false,false],[false,false],[false,false],[false,false],[false,false],[false,false],[false,false],[false,false]]
    #   }
    #   g.char == g[:char]
    #   g.width == g[:width]
    #   g.height == g[:height]
    #   g.data == g[:data]
    #
    def glyph(char)
      char = char.to_s
      ch = char.getbyte(0).to_i
      @glyphs[ch] || @nil_glyph
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

      # handle newlines properly.
      if string.include?("\n")
        w = 0
        h = 0
        lines = []
        string.split("\n").each do |line|
          w2, h2, lines2 = measure(line, max_width)
          w = w2 if w2 > w
          h += h2
          lines += lines2 if lines2
        end
        return [ w, h, lines ] if max_width > 0
        return [ w, h ]
      end

      # convert to string and replace all whitespace with actual spaces.
      # we don't support tabs or care about carriage returns.
      # we also want to reduce all whitespace sequences to a single space.
      string = string.to_s.gsub(/\s/, ' ').gsub(/\s\s+/, ' ')

      if max_width > 0
        # we are trying to fit the string into a specific width.

        # no need to measure an empty string.
        return [ 0, height, [ string ]] if string == ''

        # measure the initial string.
        w, h = measure(string)

        # we fit or there are no spaces to wrap on.
        if w <= max_width || !string.include?(' ')
          return [w, h, [ string ]]
        else

          # prepare to wrap on word boundaries.
          cur_line,_,next_line = string.rpartition(' ')

          # keep chopping off words until we can't chop any more off or we fit.
          while true
            # measure the current line.
            w, h = measure(cur_line)

            if w <= max_width || !cur_line.include?(' ')
              # we fit or we can't split anymore.

              # measure up the rest of the string.
              w2, h2, lines = measure(next_line, max_width)

              # and adjust the size as needed.
              w = w2 if w2 > w
              h += h2

              # return the adjusted size and the lines.
              return [ w, h, [ cur_line ] + lines ]
            end

            # chop off the next word.
            cur_line,_,next_word = cur_line.rpartition(' ')

            # add the chopped off word to the beginning of the next line.
            next_line = next_word + ' ' + next_line
          end
        end


      else
        # we are not trying to fit the string.

        # no need to measure an empty string.
        return [ 0, height ] if string == ''

        h = height
        w = glyphs(string).inject(0) { |_w,g| _w + g[:width] }

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
      "#{name} #{bold ? 'Bold' : 'Regular'} #{size}pt"
    end

    def freeze # :nodoc
      name.freeze
      size.freeze
      bold.freeze
      super
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

    private

    def add_glyph_helpers_to(glyph)
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
      glyph
    end

  end
end


# Include the components of the model.
Dir.glob(File.expand_path('../font/*.rb', __FILE__)).each do |file|
  require file
end
