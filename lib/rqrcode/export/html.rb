# frozen_string_literal: true

module RQRCode
  module Export
    module HTML
      #
      # Use this module to HTML-ify the QR code if you just want the default HTML
      def as_html
        ["<table>", rows.as_html, "</table>"].join
      end

      private

      def rows
        Rows.new(@qrcode)
      end

      class Rows < Struct.new(:qr)
        def as_html
          rows.map(&:as_html).join
        end

        def rows
          qr.modules.each_with_index.map { |qr_module, row_index| Row.new(qr, qr_module, row_index) }
        end
      end

      class Row < Struct.new(:qr, :qr_module, :row_index)
        def as_html
          ["<tr>", cells.map(&:as_html).join, "</tr>"].join
        end

        def cells
          qr.modules.each_with_index.map { |qr_module, col_index| Cell.new(qr, col_index, row_index) }
        end
      end

      class Cell < Struct.new(:qr, :col_index, :row_index)
        def as_html
          "<td class=\"#{html_class}\"></td>"
        end

        def html_class
          qr.checked?(row_index, col_index) ? "black" : "white"
        end
      end
    end
  end
end

RQRCode::QRCode.send :include, RQRCode::Export::HTML
