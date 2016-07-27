# BarkestLcd

This gem is designed to make it easy to interface with some LCD displays.  

I wanted to add a front panel LCD to a server I was building, so I started this project to address interacting with
the LCD panel I picked up.

Currently it works with the PicoLCD from [www.mini-box.com](http://www.mini-box.com/picoLCD-256x64-Sideshow-CDROM-Bay).

The gem uses the [hid_api](https://github.com/gareth/ruby_hid_api) gem to interface with the picoLCD.  I apply a few
patches to the HidApi::Device class to make it play nice.  Notably by fixing the `close` method and making the `read`
and `read_timeout` methods return only the bytes read.


## Installation

This gem depends on [HID API](http://www.signal11.us/oss/hidapi/).

Installation of the dependency is specific to the environment.

For OS X (using homebrew):

    $ brew install hidapi
    
For Ubuntu/Debian:

    $ sudo apt-get install libhidapi-libusb0
    $ cd /usr/lib/x86_64-linux-gnu
    $ sudo ln -s libhidapi-libusb.so.0.0.0 libhidapi.so


Add this line to your application's Gemfile:

```ruby
gem 'barkest_lcd'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install barkest_lcd


## Usage

Let's assume you have one picoLCD 256x64 device attached to your computer.  Usage is fairly simple.

This example will draw a 32x32 rectangle with an X in it.

```ruby
my_device = BarkestLcd::PicoLcdGraphic.first
my_device.open
my_device.draw_rect(40, 4, 32, 32).draw_line(40, 4, 72, 36).draw_line(40, 36, 72, 4)
my_device.paint
```

As you can see, most of the methods are chainable.  Unless the method has an explicit return value (like `open?`) then
the method should be returning the device model.  The `open`, `close`, and `paint` methods are all chainable as well.

There are currently some very basic drawing methods included by the `SimpleGraphic` module.  These include `set_bit`,
`draw_vline`, `draw_hline`, `draw_line`, and `draw_rect`.  The `clear` method will clear the screen.

Continuing, we will wait for the user to press the OK button.

```ruby
OK_BUTTON = 6
ok_pressed = false

# set the callback to process keys when they are released.
my_device.on_key_up do |key|
  if key == OK_BUTTON
    ok_pressed = true
  end
end

# use the "loop" function to process events with the device and update the screen.
until ok_pressed
  my_device.loop
end
```

In this case we set the `on_key_up` callback to set a flag when the OK button is pressed.  If we wanted to do repeating
keys when a user holds down a button, we may want to set the `on_key_down` or use the `key_state` method within the loop.

Finally, I recommend closing the device when you are finished.  Ruby will close the device when it exits, but if you
are handling errors and such, closing the device explicitly in an `ensure` block will help to protect you against being
unable to open the device again.

```ruby
my_device.clear.paint
my_device.close
```

It is not necessary to clear the screen before closing, but doing so ensures that you do not leave weird information
or screen artifacts up when your application is done.



## Credits

*   The [picoLCD 256x64 Suite Source](http://resources.mini-box.com/online/picolcd/256x64/1003/PicoLCD256x64_src.zip)
    provided most of the information needed to make this gem interact with the picoLCD 256x64 from 
    [mini-box](http://www.mini-box.com).
*   The [picoLCD256x64](https://github.com/itszero/picoLCD256x64) project provided some inspiration, but I ended up going
    a completely different direction.


## License

Copyright (c) 2016 [Beau Barker](mailto:beau@barkerest.com)

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

