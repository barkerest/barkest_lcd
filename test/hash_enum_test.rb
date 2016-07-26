require 'test_helper'

class HashEnumTest < Test::Unit::TestCase

  TEST_HASH = {alpha: 0x01, bravo: 0x02, charlie: 0x04, delta: 0x08, echo: 0x10, foxtrot: 0x20}

  def setup
    @enum = BarkestLcd::HashEnum.new(TEST_HASH)
  end

  test 'should function as a hash' do
    # first the keys.
    TEST_HASH.each do |k,v|
      assert_equal v, @enum[k], "value for #{k} should be #{v}"
    end
  end

  test 'should be read only' do
    assert_equal true, @enum.frozen?

    assert_raise RuntimeError do
      @enum[:golf] = 0x40
    end

    assert_raise RuntimeError do
      @enum[:foxtrot] = 0x40
    end
  end

  test 'should respond to keys as methods' do
    assert_equal TEST_HASH[:alpha], @enum.alpha
    assert_equal TEST_HASH[:bravo], @enum.bravo
    assert_equal TEST_HASH[:charlie], @enum.CHARLIE
    assert_equal TEST_HASH[:delta], @enum.DELTA
    assert_equal TEST_HASH[:echo], @enum.echo
    assert_equal TEST_HASH[:foxtrot], @enum.FOXTROT
  end

  test 'should have flag tests' do
    assert_equal true, @enum.alpha?(5)
    assert_equal false, @enum.bravo?(5)
    assert_equal true, @enum.charlie?(5)
    assert_equal false, @enum.delta?(5)
    assert_equal false, @enum.echo?(5)
    assert_equal false, @enum.foxtrot?(5)
    assert_equal true, @enum.ALPHA?(5)
    assert_equal false, @enum.BRAVO?(5)
    assert_equal true, @enum.CHARLIE?(5)
  end

  test 'should be able to reverse flags' do
    flags = @enum.flags(77)  # 64 + 8 + 4 + 1
    expected = [ :delta, :charlie, :alpha, 64 ]
    assert_equal expected, flags
  end

end