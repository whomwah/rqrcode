# RQRCode

![](https://github.com/whomwah/rqrcode/actions/workflows/ruby.yml/badge.svg)


[RQRCode](https://github.com/whomwah/rqrcode) is a library for creating and rendering QR codes into various formats. It has a simple interface with all the standard QR code options. It was adapted from the Javascript library by Kazuhiko Arase.

* QR code is trademarked by Denso Wave inc
* Minimum Ruby version is `>= 2.3`
* For `rqrcode` releases `< 1.0.0` please use [this README](https://github.com/whomwah/rqrcode/blob/cd2732a68434e6197c219e6c8cbdadfce0c4c4f3/README.md)

## Installing

Add this line to your application's `Gemfile`:

```ruby
gem 'rqrcode'
```

or install manually:

```ruby
gem install rqrcode
```

## Basic usage example

```ruby
require 'rqrcode'

qr = RQRCode::QRCode.new('https://kyan.com')

puts qr.to_s

xxxxxxx xxxxxxx  xxx  xxxxxxx
x     x  x  xxx   xx  x     x
x xxx x xx x x     xx x xxx x
x xxx x      xx xx xx x xxx x
x xxx x x x       xxx x xxx x
x     x  xxx x xx x x x     x
...
```

### Advanced Options

These are the various QR Code generation options provided by [rqrqcode_core](https://github.com/whomwah/rqrcode_core).

```
string - the string you wish to encode

size   - the size of the qrcode (default 4)

level  - the error correction level, can be:
  * Level :l 7%  of code can be restored
  * Level :m 15% of code can be restored
  * Level :q 25% of code can be restored
  * Level :h 30% of code can be restored (default :h)

mode   - the mode of the qrcode (defaults to alphanumeric or byte_8bit, depending on the input data):
  * :number
  * :alphanumeric
  * :byte_8bit
  * :kanji
```

Example

```
qrcode = RQRCodeCore::QRCode.new('hello world', size: 1, level: :m, mode: :alphanumeric)
```

## Render types

You probably want to output your QR code in a specific format. We make this easy by providing a bunch of formats to choose from below, each with their own set of options:

### as SVG

The SVG renderer will produce a stand-alone SVG as a `String`

```
Options:

offset          - Padding around the QR Code in pixels
                  (default 0)
fill            - Background color e.g "ffffff" or :white
                  (default none)
color           - Foreground color e.g "000" or :black
                  (default "000")
module_size     - The Pixel size of each module
                  (defaults 11)
shape_rendering - SVG Attribute: auto | optimizeSpeed | crispEdges | geometricPrecision
                  (defaults crispEdges)
standalone      - whether to make this a full SVG file, or only an svg to embed in other svg
                  (default true)
```
Example
```ruby
require 'rqrcode'

qrcode = RQRCode::QRCode.new("http://github.com/")

# NOTE: showing with default options specified explicitly
svg = qrcode.as_svg(
  offset: 0,
  color: '000',
  shape_rendering: 'crispEdges',
  module_size: 11,
  standalone: true
)
```

![QR code with github url](./images/github-qrcode.svg)

### as PNG

The will produce a PNG using the [ChunkyPNG gem](https://github.com/wvanbergen/chunky_png). The result will be a `ChunkyPNG::Image` instance.

```
Options:

fill  - Background ChunkyPNG::Color, defaults to 'white'
color - Foreground ChunkyPNG::Color, defaults to 'black'

When option :file is supplied you can use the following ChunkyPNG constraints:

color_mode  - The color mode to use. Use one of the ChunkyPNG::COLOR_* constants.
              (defaults to 'ChunkyPNG::COLOR_GRAYSCALE')
bit_depth   - The bit depth to use. This option is only used for indexed images.
              (defaults to 1 bit)
interlace   - Whether to use interlacing (true or false).
              (defaults to ChunkyPNG default)
compression - The compression level for Zlib. This can be a value between 0 and 9, or a
              Zlib constant like Zlib::BEST_COMPRESSION
              (defaults to ChunkyPNG default)

There are two sizing algorithms.

* Original that can result in blurry and hard to scan images
* Google's Chart API inspired sizing that resizes the module size to fit within the given image size.

The Google one will be used when no options are given or when the new size option is used.

*Google Sizing*

size            - Total size of PNG in pixels. The module size is calculated so it fits.
                  (defaults to 120)
border_modules  - Width of white border around the modules.
                  (defaults to 4).

-- DONT USE border_modules OPTION UNLESS YOU KNOW ABOUT THE QUIET ZONE NEEDS OF QR CODES --

*Original Sizing*

module_px_size  - Image size, in pixels.
border          - Border thickness, in pixels

It first creates an image where 1px = 1 module, then resizes.
Defaults to 120x120 pixels, customizable by option.
```

Example

```ruby
require 'rqrcode'

qrcode = RQRCode::QRCode.new("http://github.com/")

# NOTE: showing with default options specified explicitly
png = qrcode.as_png(
  bit_depth: 1,
  border_modules: 4,
  color_mode: ChunkyPNG::COLOR_GRAYSCALE,
  color: 'black',
  file: nil,
  fill: 'white',
  module_px_size: 6,
  resize_exactly_to: false,
  resize_gte_to: false,
  size: 120
)

IO.binwrite("/tmp/github-qrcode.png", png.to_s)
```

![QR code with github url](./images/github-qrcode.png)


### as ANSI

The ANSI renderer will produce as a string with ANSI color codes.

```
Options:

light           - Foreground ANSI code
                  (default "\033[47m")
dark            - Background ANSI code
                  (default "\033[40m")
fill_character  - The written character
                  (default '  ')
quiet_zone_size - Padding around the edge
                  (default 4)
```
Example
```ruby
require 'rqrcode'

qrcode = RQRCode::QRCode.new("http://github.com/")

# NOTE: showing with default options specified explicitly
svg = qrcode.as_ansi(
  light: "\033[47m", dark: "\033[40m",
  fill_character: '  ',
  quiet_zone_size: 4
)
```

![QR code with github url](./images/ansi-screen-shot.png)

## API Documentation

[http://www.rubydoc.info/gems/rqrcode](http://www.rubydoc.info/gems/rqrcode)

## Tests

You can run the test suite using:

```
$ ./bin/setup
$ rake      # runs specs and standard:fix
$ rake spec # just runs the specs
```

or try the lib from the console with:

```
$ ./bin/console
```

## Linting

The project uses [standardrb](https://github.com/testdouble/standard) and can be used with:

```
$ ./bin/setup
$ rake standard # checks
$ rake standard:fix # fixes
```

## Contributing

The current plan moving forward is to move `as_png`, `as_css`, `as_svg`, `as_ansi` etc into their own gems so they can be managed independently -- ideally -- by people who are interested in maintaining a specific render type. This will leave me to look after `rqrcode_core` gem which I do have time for.

So for example if you only required a `png` rendering of a QR Code, you could simply use the gem `rqrcode_png`. This would eventually mean that the `rqrcode` gem will just become a bucket that pulls in all the existing renderings only and would have deprecated usage over time.

So, the motivation behind all this change is because the rendering side of this gem takes up the most time. It seems that many people want a slightly different version of a QR Code so supporting all the variations would be hard. The easiest way is to empower people to create their own versions which they can manage and share.

The work won't impact any current users of this gem. What this does mean though is that any contribution PR's should *only* be bug fixes rather than new functionality. Thanks D.

* Fork the project
* Send a pull request
* Don't touch the .gemspec, I'll do that when I release a new version

## Authors

Original RQRCode author: Duncan Robertson

A massive thanks to [all the contributors of the library over the years](https://github.com/whomwah/rqrcode/graphs/contributors). It wouldn't exist if it wasn't for you all.

Oh, and thanks to my bosses at https://kyan.com for giving me time to maintain this project.

## Resources

* wikipedia:: http://en.wikipedia.org/wiki/QR_Code
* Denso-Wave website:: http://www.denso-wave.com/qrcode/index-e.html
* kaywa:: http://qrcode.kaywa.com

## Copyright

MIT License (http://www.opensource.org/licenses/mit-license.html)
