require 'chunky_png'

# This class creates PNG files.
# Code from: https://github.com/DCarper/rqrcode
module RQRCode
  module Export
    module PNG

      # Render the PNG from the Qrcode.
      #
      # Options:
      # module_px_size  - Image size, in pixels.
      # fill  - Background ChunkyPNG::Color, defaults to 'white'
      # color - Foreground ChunkyPNG::Color, defaults to 'black'
      # border - Border thickness, in pixels
      #
      # It first creates an image where 1px = 1 module, then resizes.
      # Defaults to 90x90 pixels, customizable by option.
      #
      def as_png(options = {})

        default_img_options = {
          :resize_gte_to => false,
          :resize_exactly_to => false,
          :fill => 'white',
          :color => 'black',
          :border_modules => 4,
          :file => false,
          :module_px_size => 6
        }
        options = default_img_options.merge(options) # reverse_merge

        fill   = ChunkyPNG::Color(options[:fill])
        color  = ChunkyPNG::Color(options[:color])
        output_file = options[:file]
        border = options[:border_modules]
        total_border = border * 2
        module_px_size = if options[:resize_gte_to]
          (options[:resize_gte_to].to_f / (self.module_count + total_border).to_f).ceil.to_i
        else
          options[:module_px_size]
        end
        border_px = border *  module_px_size
        total_border_px = border_px * 2
        resize_to = options[:resize_exactly_to]

        img_size = module_px_size * self.module_count
        total_img_size = img_size + total_border_px

        png = ChunkyPNG::Image.new(total_img_size, total_img_size, fill)

        self.modules.each_index do |x|
          self.modules.each_index do |y|
            if self.dark?(x, y)
              (0...module_px_size).each do |i|
                (0...module_px_size).each do |j|
                  png[(y * module_px_size) + border_px + j , (x * module_px_size) + border_px + i] = color
                end
              end
            end
          end
        end

        png = png.resize(resize_to, resize_to) if resize_to

        if output_file
          png.save(output_file,{ :color_mode => ChunkyPNG::COLOR_GRAYSCALE, :bit_depth =>1})
        end
        png
      end

    end
  end
end

RQRCode::QRCode.send :include, RQRCode::Export::PNG
