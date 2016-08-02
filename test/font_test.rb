require 'test_helper'

class FontTest < Test::Unit::TestCase

  def setup
    @font1 = BarkestLcd::Font.regular
    @font2 = BarkestLcd::Font.bold
  end

  test 'should be able to measure text' do
    string = 'Hello World'

    # very simple, every character in the string is printable, so we should have a glyph for each character.
    glyphs1 = @font1.glyphs(string)
    assert_equal string.length, glyphs1.count

    glyphs2 = @font2.glyphs(string)
    assert_equal string.length, glyphs2.count

    # the measure method should be processing the same glyphs.
    # so we'll simply grab the width from the glyphs and the height from the font and then compare against measure.
    w1 = glyphs1.inject(0) { |w,g| w + g.width }
    w2 = glyphs2.inject(0) { |w,g| w + g.width }

    # now we measure the string
    w, h = @font1.measure(string)
    assert_equal w1, w
    assert_equal @font1.height, h

    w, h = @font2.measure(string)
    assert_equal w2, w
    assert_equal @font2.height, h
  end

  test 'should be able to limit width on text measurement' do
    [
        'Hello World! This is a test.',       # 2+ lines
        'This is another test with a long-string-of-words-tied-together-that-should-not-be-split.',   # 2+ lines
        "This is a test.\nWith a new line."   # 4+ lines
    ].each_with_index do |string, index|
      index += 1
      raw_lines = string.split("\n").count

      [ @font1, @font2 ].each do |font|

        # so first we get the raw size.
        raw_w, raw_h = font.measure(string)

        assert_equal font.height * raw_lines, raw_h, "measured height does not match font height for #{font} and string #{index}"

        # now we want to fit it into a space half as wide as it needs.
        w, h, lines = font.measure(string, raw_w / 2)

        # there should be at least two lines returned, probably more.
        assert (lines.count >= raw_lines + 1), "measured text was not split into additional lines for #{font} and string #{index}"

        # the height should be greater than the raw height.
        # it should match the raw_h times the line count.
        assert (h == font.height * lines.count), "measured height does not match line couunt for #{font} and string #{index}"

      end
    end
  end



end