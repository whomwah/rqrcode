# This class creates a SVG files.
# Code from: https://github.com/samvincent/rqrcode-rails3
module RQRCode
  module Export

    module SVG

      # Render the SVG from the Qrcode.
      #
      # Options:
      # offset - Padding around the QR Code (e.g. 10)
      # fill - Background color (e.g "ffffff" or :white)
      # color - Foreground color for the code (e.g. "000000" or :black)
      # module_size - The Pixel size of each module (e.g. 11)
      # shape_rendering - Defaults to crispEdges
      #
      def as_svg(options={})
        Renderer.new(self, options).render
      end

      def as_svg_renderer(options={})
        Renderer.new(self, options)
      end
    end

    private

    class Renderer
      def initialize(qrcode, options)
        @offset = options[:offset].to_i || 0
        @style_dark = "fill:#" + (options[:color] || "000")
        @style_light = options[:fill] && "fill:#" + options[:fill]
        @shape_rendering = options[:shape_rendering] || "crispEdges"
        @module_size = options[:module_size] || 11
        @qrcode = qrcode
      end

      def render
        # height and width dependent on offset and QR complexity
        dimension = (@qrcode.module_count*@module_size) + (2*@offset)

        xml_tag = %{<?xml version="1.0" standalone="yes"?>}
        open_tag = %{<svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:ev="http://www.w3.org/2001/xml-events" width="#{dimension}" height="#{dimension}" shape-rendering="#{@shape_rendering}">}
        close_tag = "</svg>"

        result = []
        @qrcode.modules.each_index do |c|
          tmp = []
          @qrcode.modules.each_index do |r|
            y = c*@module_size + @offset
            x = r*@module_size + @offset

            next unless @qrcode.is_dark(c, r)
            tmp << %{<rect width="#{@module_size}" height="#{@module_size}" x="#{x}" y="#{y}" style="#{@style_dark}"/>}
          end
          result << tmp.join
        end

        if @style_light
          result.unshift %{<rect width="#{dimension}" height="#{dimension}" x="0" y="0" style="#{@style_light}"/>}
        end

        [xml_tag, open_tag, result, close_tag].flatten.join("\n")
      end

      def styles
        @style_light ? [@style_dark, @style_light] : [@style_dark]
      end
    end
  end
end

RQRCode::QRCode.send :include, RQRCode::Export::SVG
