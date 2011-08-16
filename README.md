# rQRCode, Encode QRCodes

## Overview

rQRCode is a library for encoding QR Codes in Ruby. It has a simple interface with all the standard qrcode options. It was adapted from the Javascript library by Kazuhiko Arase.

Let's clear up some rQRCode stuff.

* rQRCode is a __standalone library__ It requires no other libraries. Just Ruby!
* It is an encoding library. You can't decode QR codes with it.
* The interface is simple and assumes you just want to encode a string into a QR code
* QR code is trademarked by Denso Wave inc

## Resources

* wikipedia:: http://en.wikipedia.org/wiki/QR_Code
* Denso-Wave website:: http://www.denso-wave.com/qrcode/index-e.html
* kaywa:: http://qrcode.kaywa.com

## Installing

You may get the latest stable version from Rubygems. 

    gem install rqrcode

You can also get the latest source from http://github.com/whomwah/rqrcode

    git clone git://github.com/whomwah/rqrcode.git

## Tests

To run the tests:

    $ rake
 
## Loading rQRCode Itself

You have installed the gem already, yeah?

    require 'rubygems'
    require 'rqrcode'

## Simple QRCode generation to screen

```ruby
qr = RQRCode::QRCode.new( 'my string to generate', :size => 4, :level => :h )
puts qr.to_s
#
# Prints:
# xxxxxxx x  x x   x x  xx  xxxxxxx
# x     x  xxx  xxxxxx xxx  x     x
# x xxx x  xxxxx x       xx x xxx x
# ... etc
```

## Simple QRCode generation to template (RubyOnRails)

```erb
# Controller
@qr = RQRCode::QRCode.new( 'my string to generate', :size => 4, :level => :h )

# View: (minimal styling added)
<style type="text/css">
table {
  border-width: 0;
  border-style: none;
  border-color: #0000ff;
  border-collapse: collapse;
}
td {
  border-width: 0; 
  border-style: none;
  border-color: #0000ff; 
  border-collapse: collapse; 
  padding: 0; 
  margin: 0; 
  width: 10px; 
  height: 10px; 
}
td.black { background-color: #000; }
td.white { background-color: #fff; }
</style>

<table>
<% @qr.modules.each_index do |x| %>
  <tr>  
  <% @qr.modules.each_index do |y| %>
   <% if @qr.dark?(x,y) %>
    <td class="black"/>
   <% else %>
    <td class="white"/>
   <% end %>
  <% end %>
  </tr>
<% end %>
</table>
```

## Authors

Original author: Duncan Robertson

Special thanks to the following people for submitting patches:

* [Gioele Barabucci](https://github.com/gioele) 
* [Rob la Lau](https://github.com/ohreally)
* [Chris Mowforth](http://blog.99th.st)
* [Tore Darell](http://tore.darell.no)
* [Daniel Schierbeck](https://github.com/dasch)
* Vladislav Gorodetskiy

## Contributing
* Fork the project
* Send a pull request
* Don't touch the .gemspec, I'll do that when I release a new version

## Copyright

MIT Licence (http://www.opensource.org/licenses/mit-license.html)
