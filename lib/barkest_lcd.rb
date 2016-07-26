require 'barkest_lcd/version'
require 'hid_api'

module BarkestLcd

end


# :nodoc:
HidApi::Device.class_eval do

  # :nodoc:
  def close
    # the gem (as of 0.1.1) calls HidApi.close, which does not exist.
    HidApi.hid_close(self)
  end

  # :nodoc:
  def read(length)
    buffer = clear_buffer length
    # the gem (as of 0.1.1) ignores the number of bytes read.
    # cache it and then return just the bytes read.
    read_length =
        with_hid_error_handling do
          HidApi.hid_read self, buffer, buffer.length
        end
    buffer.get_bytes(0, read_length)
  end

  # :nodoc:
  def read_timeout(length, timeout)
    buffer = clear_buffer length
    # the gem (as of 0.1.1) ignores the number of bytes read.
    # cache it and then return just the bytes read.
    read_length =
        with_hid_error_handling do
          HidApi.hid_read_timeout self, buffer, buffer.length, timeout
        end
    buffer.get_bytes(0, read_length)
  end
end

Dir.glob(File.expand_path('../models/*.rb', __FILE__)).each do |file|
  require file
end
