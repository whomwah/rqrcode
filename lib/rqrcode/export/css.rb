module RQRCode
  module Export
    module CSS

      def as_css(options={})
        id = options.fetch(:id, "qrcode")
        clazz = options.fetch(:id, "qrcode-container")
        base_size = options.fetch(:size, 200)
        @@qr_logo = options.fetch(:logo, nil)
        @@qr_logo_size = options.fetch(:logo_size, 32)
        @@qr_data = to_s.split("\n").collect(&:chars)
        @@qr_size = @@qr_data.size
        @@bit_size = base_size / @@qr_size.to_f;

        "<div id='#{id}' class='#{clazz}'>#{create_qr_css}</div>"
      end

      private

      def create_qr_css
        str = "<div class='qr-inner'>"
        str << qr_content
        str << logo if @@qr_logo
        str << "</div>"
      end

      def qr_content
        @@qr_data.each_with_index.collect{|row, r| make_row(row, r)}.join
      end

      def make_row(row, r)
        str = "<div style='height: #{@@bit_size}px;' class='r'>"
        str << row.each_with_index.collect{|col, c| make_col(col, c, r) }.join
        str << "</div>"
      end

      def make_col(col, c, r)
        "<div style='width:#{@@bit_size}px; height:#{@@bit_size}px;' class='c #{class_for_position(r, c)}'></div>"
      end

      def class_for_position(r, c)
        if active?(r,c)
          if anchor_position?(r,c)
            clazz = "square"
            clazz << " #{class_for_anchor(r,c)}"
          else
            clazz = "round"
          end
        end
        clazz
      end

      def active?(r,c)
        @@qr_data[r][c] == "x"
      end

      def anchor_position?(r, c)
        (r < 7 && c < 7) || (r >= @@qr_size - 7 && c < 7) || (r < 7 && c >= @@qr_size - 7 )
      end

      def class_for_anchor(r,c)
        o_top = r == 0 || r == @@qr_size - 7
        o_bottom = r == 6 || r == @@qr_size -1
        o_left = c == 0 || c == @@qr_size - 7
        o_right = c == 6 || c == @@qr_size - 1

        i_top = r == 2 || r == @@qr_size - 5
        i_bottom = r == 4 || r == @@qr_size -3
        i_left = c == 2 || c == @@qr_size - 5
        i_right = c == 4 || c == @@qr_size - 3

        clazz = ""
        if o_top && o_left || i_top && i_left
          clazz << "rounded-tl"
        end
        if o_top && o_right || i_top && i_right
          clazz << "rounded-tr"
        end
        if o_bottom && o_left || i_bottom && i_left
          clazz << "rounded-bl"
        end
        if o_bottom && o_right || i_bottom && i_right
          clazz << "rounded-br"
        end
        clazz << " outter" if o_top || o_bottom || o_left || o_right
        clazz << " inner" if i_top || i_bottom || i_left || i_right
        clazz
      end

      def logo
        margin = @@qr_logo_size / 2
        "<img src='#{@@qr_logo}' height='#{@@qr_logo_size}' width='#{@@qr_logo_size}' style='margin-top: -#{margin}px; margin-left: -#{margin}px' />"
      end
    end
  end
end
RQRCode::QRCode.send :include, RQRCode::Export::CSS
