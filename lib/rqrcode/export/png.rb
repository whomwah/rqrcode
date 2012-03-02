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
      # border - Border thickness, in pixels
      #
      # It first creates an image where 1px = 1 module, then resizes.
      # Defaults to 90x90 pixels, customizable by option.
      #
      def as_png(options = {})

        default_img_options = {
          :resize_to => false,
          :fill => 'white',
          :color => 'black',
          :border => 2,
          :file => false,
          :px_multiplier => 4
        }
        options = default_img_options.merge(options) # reverse_merge

        fill   = ChunkyPNG::Color(options[:fill])
        color  = ChunkyPNG::Color(options[:color])
        output_file = options[:file]
        border = options[:border]
        total_border = border * 2
        px_multiplier = options[:px_multiplier]
        resize_to = options[:resize_to]

        img_size = px_multiplier * self.module_count# a square 33 by 33 "modules"
        total_img_size = img_size + total_border

        png = ChunkyPNG::Image.new(total_img_size, total_img_size, fill)

        self.modules.each_index do |x|
          self.modules.each_index do |y|
            if self.dark?(x, y)
              (0..px_multiplier).each do |i|
                (0..px_multiplier).each do |j|
                  png[(y * px_multiplier) + border + j , (x * px_multiplier) + border + i] = color
                end
              end
            end
          end
        end

        png.resize(resize_to, resize_to) if resize_to

        if output_file
          png.save(output_file,:constraints => { :color_mode => ChunkyPNG::COLOR_GRAYSCALE, :bit_depth =>1})
        end
        png
      end

    end
  end
end

RQRCode::QRCode.send :include, RQRCode::Export::PNG
