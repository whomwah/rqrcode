# This class creates a SVG files.
# Code from: https://github.com/samvincent/rqrcode-rails3
module RQRCode
  module Export

    # Render the SVG from the Qrcode.
    #
    # Options:
    # offset - Padding around the QR Code (e.g. 10)
    # fill - Background color (e.g "ffffff" or :white)
    # color - Foreground color for the code (e.g. "000000" or :black)
    module SVG
      def as_svg(options={})
        offset = options[:offset].to_i || 0
        color = options[:color] || "000"

        # height and width dependent on offset and QR complexity
        dimension = (self.module_count*11) + (2*offset)

        xml_tag = %{<?xml version="1.0" standalone="yes"?>}
        open_tag = %{<svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:ev="http://www.w3.org/2001/xml-events" width="#{dimension}" height="#{dimension}">}
        close_tag = "</svg>"

        result = []
        self.modules.each_index do |c|
          tmp = []
          self.modules.each_index do |r|
            y = c*11 + offset
            x = r*11 + offset

            next unless self.is_dark(c, r)
            tmp << %{<rect width="11" height="11" x="#{x}" y="#{y}" style="fill:##{color}"/>}
          end
          result << tmp.join
        end

        if options[:fill]
          result.unshift %{<rect width="#{dimension}" height="#{dimension}" x="0" y="0" style="fill:##{options[:fill]}"/>}
        end

        [xml_tag, open_tag, result, close_tag].flatten.join("\n")
      end
    end
  end
end

RQRCode::QRCode.send :include, RQRCode::Export::SVG
