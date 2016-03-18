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
        fixpoints = <<-EOS
<defs>
<g id="fixpoint" fill="##{color}">
<path d="M 0 0 h #{module_size * 7} v #{module_size * 7} h -#{module_size * 7} v -#{module_size} h #{module_size * 6} v -#{module_size * 5} h -#{module_size* 5} v #{module_size * 5} h -#{module_size} z"/>
<path d="M #{module_size * 2} #{module_size * 2} h #{module_size * 3} v #{module_size * 3} h -#{module_size * 3} z"/>
</g>
</defs>
<use xlink:href="#fixpoint" x="#{offset}" y="#{offset}"/>
<use xlink:href="#fixpoint" x="#{(self.module_count - 7) * module_size + offset}" y="#{offset}"/>
<use xlink:href="#fixpoint" x="#{offset}" y="#{(self.module_count - 7) * module_size + offset}"/>
EOS
        result = [%{<g fill="##{color}">}]
        self.modules.each_index do |c|
          tmp = []
          self.modules.each_index do |r|
            y = c*module_size + offset
            x = r*module_size + offset

            next unless self.is_dark(c, r)
            tmp << %{<rect width="#{module_size}" height="#{module_size}" x="#{x}" y="#{y}"/>} unless fixpoint?(r, c)
          end
          result << tmp.join
        end
        result << '</g>'

        if options[:fill]
          result.unshift %{<rect width="#{dimension}" height="#{dimension}" x="0" y="0" style="fill:##{options[:fill]}"/>}
        end

        [xml_tag, open_tag, fixpoints, result, close_tag].flatten.join("\n")
      end

      def fixpoint?(r, c)
        (0..6).member?(c) && ((0..6).member?(r) || (self.module_count-7..self.module_count-1).member?(r)) ||
        (self.module_count-7..self.module_count-1).member?(c) && (0..6).member?(r)
      end
    end
  end
end

RQRCode::QRCode.send :include, RQRCode::Export::SVG
