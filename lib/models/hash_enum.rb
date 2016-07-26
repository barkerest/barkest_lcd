module BarkestLcd
  ##
  # A simple enumeration class based on a hash of integers.
  #
  #   enum = HashEnum.new({ :alpha => 0x01, :bravo => 0x02, :charlie => 0x04 })
  #   enum.alpha        # 1
  #   enum.bravo        # 2
  #   enum.CHARLIE      # 4
  #   enum.alpha?(11)   # true
  #   enum.BRAVO?(11)   # true
  #   enum.charlie?(11) # false
  #
  class HashEnum

    ##
    # Turns a hash into an enumeration.
    def initialize(hash = {})
      @hash = hash.inject({}){ |memo,(k,v)| memo[k.to_sym] = v.to_i; memo }.freeze
      # values ordered highest to lowest.
      @flags = @hash.to_a.sort{|a,b| b[1] <=> a[1]}

      freeze
    end

    # :nodoc:
    def method_missing(meth, *args, &block)

      if @hash.respond_to?(meth)
        return @hash.send(meth, *args, &block)
      end

      [ meth.to_s.downcase.to_sym, meth.to_s.upcase.to_sym ].each do |test_meth|
        if @hash.keys.include?(test_meth)
          return @hash[test_meth]
        else
          meth_name = test_meth.to_s
          is_flag = meth_name[-1] == '?'
          if is_flag
            test_meth = meth_name[0..-2].to_sym
            if @hash.keys.include?(test_meth)
              valid = @hash[test_meth]
              test = args && args.count > 0 ? args.first : nil
              raise ArgumentError, 'Missing value to test.' unless test
              raise ArgumentError, 'Test value must be an integer.' unless test.is_a?(Fixnum)
              return (test & valid) == valid
            end
          end
        end
      end

      super meth, *args, &block
    end

    ##
    # Determines what keys the value contains.
    #
    # If a remainder exists, then the remainder is added at the end of the returned array.
    def flags(value)
      ret = []
      @flags.each do |(k,v)|
        if (value & v) == v
          value -= v
          ret << k
        end
      end
      ret << value if value != 0
      ret
    end

    # :nodoc:
    def inspect
      @hash.inspect
    end

    # :nodoc:
    def to_s
      @hash.to_s
    end

    # :nodoc:
    def ==(other)
      @hash == other
    end

    # :nodoc:
    def eql?(other)
      @hash.eql?(other)
    end

  end
end
