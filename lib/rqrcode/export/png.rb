require 'chunky_png'

# This class creates PNG files.
# Code from: https://github.com/DCarper/rqrcode
module RQRCode
  module Export
    module PNG

      # Render the PNG from the Qrcode.
      #
      # Options:
      # size  - Image size, in pixels.
      # fill  - Background ChunkyPNG::Color, defaults to 'white'
      # color - Foreground ChunkyPNG::Color, defaults to 'black'
      #
      # It first creates a 33x33 image and then resizes it up.
      # Defaults to 90x90 pixels, customizable by option.
      #
      def as_png(options = {})

        default_img_options = { :size => 90 }
        options = default_img_options.merge(options) # reverse_merge

        fill   = ChunkyPNG::Color(options[:fill]  || 'white')
        color  = ChunkyPNG::Color(options[:color] || 'black')
        border = 2
        total_border = border * 2

        img_size = 33 # a square 33 by 33 "modules"
        total_img_size = img_size + total_border

        png = ChunkyPNG::Image.new(total_img_size, total_img_size, fill)

        self.modules.each_index do |x|
          self.modules.each_index do |y|
            if self.dark?(x, y)
              png[y + border , x+border] = color
            end
          end
        end

        png.resize(options[:size], options[:size])
      end

    end
  end
end

RQRCode::QRCode.send :include, RQRCode::Export::PNG
