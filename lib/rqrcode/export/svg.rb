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
        offset = options[:offset].to_i || 0
        color = options[:color] || "000"
        shape_rendering = options[:shape_rendering] || "crispEdges"
        module_size = options[:module_size] || 11

        # height and width dependent on offset and QR complexity
        dimension = (self.module_count*module_size) + (2*offset)

        xml_tag = %{<?xml version="1.0" standalone="yes"?>}
        open_tag = %{<svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 #{dimension} #{dimension}" shape-rendering="#{shape_rendering}">}
        close_tag = "</svg>"
        style_tag = <<-EOS
<style type="text/css"><![CDATA[
rect {width:#{module_size}px; height:#{module_size}px}
]]></style>
        EOS

        result = [%{<g fill="##{options[:color]}">}]
        self.modules.each_index do |c|
          tmp = []
          self.modules.each_index do |r|
            y = c*module_size + offset
            x = r*module_size + offset

            next unless self.is_dark(c, r)
            tmp << %{<rect x="#{x}" y="#{y}"/>}
          end
          result << tmp.join
        end
        result << '</g>'

        if options[:fill]
          result.unshift %{<rect width="#{dimension}" height="#{dimension}" x="0" y="0" style="fill:##{options[:fill]}"/>}
        end

        [xml_tag, open_tag, style_tag, result, close_tag].flatten.join("\n")
      end
    end
  end
end

RQRCode::QRCode.send :include, RQRCode::Export::SVG
