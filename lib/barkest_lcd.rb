require 'barkest_lcd/version'
require 'hidapi'

module BarkestLcd

end

Dir.glob(File.expand_path('../models/*.rb', __FILE__)).each do |file|
  require file
end
