#!/usr/bin/env ruby

#--
# Copyright 2004 by Duncan Robertson (duncan@whomwah.com).
# All rights reserved.

# Permission is granted for use, copying, modification, distribution,
# and distribution of modified versions of this work as long as the
# above copyright notice is included.
#++

module RQRCode #:nodoc:

  class QRUtil

    PATTERN_POSITION_TABLE = [
      
      [],
      [6, 18],
      [6, 22],
      [6, 26],
      [6, 30],
      [6, 34],
      [6, 22, 38],
      [6, 24, 42],
      [6, 26, 46],
      [6, 28, 50],
      [6, 30, 54],    
      [6, 32, 58],
      [6, 34, 62],
      [6, 26, 46, 66],
      [6, 26, 48, 70],
      [6, 26, 50, 74],
      [6, 30, 54, 78],
      [6, 30, 56, 82],
      [6, 30, 58, 86],
      [6, 34, 62, 90],
      [6, 28, 50, 72, 94],
      [6, 26, 50, 74, 98],
      [6, 30, 54, 78, 102],
      [6, 28, 54, 80, 106],
      [6, 32, 58, 84, 110],
      [6, 30, 58, 86, 114],
      [6, 34, 62, 90, 118],
      [6, 26, 50, 74, 98, 122],
      [6, 30, 54, 78, 102, 126],
      [6, 26, 52, 78, 104, 130],
      [6, 30, 56, 82, 108, 134],
      [6, 34, 60, 86, 112, 138],
      [6, 30, 58, 86, 114, 142],
      [6, 34, 62, 90, 118, 146],
      [6, 30, 54, 78, 102, 126, 150],
      [6, 24, 50, 76, 102, 128, 154],
      [6, 28, 54, 80, 106, 132, 158],
      [6, 32, 58, 84, 110, 136, 162],
      [6, 26, 54, 82, 110, 138, 166],
      [6, 30, 58, 86, 114, 142, 170]
    ]

    G15 = 1 << 10 | 1 << 8 | 1 << 5 | 1 << 4 | 1 << 2 | 1 << 1 | 1 << 0  
    G18 = 1 << 12 | 1 << 11 | 1 << 10 | 1 << 9 | 1 << 8 | 1 << 5 | 1 << 2 | 1 << 0
    G15_MASK = 1 << 14 | 1 << 12 | 1 << 10 | 1 << 4 | 1 << 1

    DEMERIT_POINTS_1 = 3
    DEMERIT_POINTS_2 = 3
    DEMERIT_POINTS_3 = 40
    DEMERIT_POINTS_4 = 10

    def QRUtil.get_bch_type_info( data )
      d = data << 10
      while QRUtil.get_bch_digit(d) - QRUtil.get_bch_digit(G15) >= 0
        d ^= (G15 << (QRUtil.get_bch_digit(d) - QRUtil.get_bch_digit(G15)))
      end
      (( data << 10 ) | d) ^ G15_MASK
    end


    def QRUtil.get_bch_type_number( data )
      d = data << 12
      while QRUtil.get_bch_digit(d) - QRUtil.get_bch_digit(G18) >= 0
        d ^= (G18 << (QRUtil.get_bch_digit(d) - QRUtil.get_bch_digit(G18)))
      end
      ( data << 12 ) | d
    end


    def QRUtil.get_bch_digit( data )
      digit = 0

      while data != 0
        digit = digit + 1
        data = (data).rszf(1)
      end

      digit
    end


    def QRUtil.get_pattern_position( type_number )
      PATTERN_POSITION_TABLE[ type_number - 1 ]
    end


    def QRUtil.get_mask( mask_pattern, i, j )
      if mask_pattern > QRMASKCOMPUTATIONS.size
        raise QRCodeRunTimeError, "bad mask_pattern: #{mask_pattern}"  
      end

      return QRMASKCOMPUTATIONS[mask_pattern].call(i, j)
    end


    def QRUtil.get_error_correct_polynomial( error_correct_length )
      a = QRPolynomial.new( [1], 0 )

      ( 0...error_correct_length ).each do |i|
        a = a.multiply( QRPolynomial.new( [1, QRMath.gexp(i)], 0 ) )
      end

      a
    end


    def QRUtil.get_length_in_bits( mode, type )
      if 1 <= type && type < 10

        # 1 - 9
        case mode
        when QRMODE[:mode_number] then  10
        when QRMODE[:mode_alpha_num] then 9
        when QRMODE[:mode_8bit_byte] then 8
        when QRMODE[:mode_kanji] then 8
        else
          raise QRCodeRunTimeError, "mode: #{mode}"
        end

      elsif type < 27

        # 10 -26
        case mode
        when QRMODE[:mode_number] then  12
        when QRMODE[:mode_alpha_num] then 11
        when QRMODE[:mode_8bit_byte] then 16
        when QRMODE[:mode_kanji] then 10
        else
          raise QRCodeRunTimeError, "mode: #{mode}"
        end

      elsif type < 41

        # 27 - 40
        case mode
        when QRMODE[:mode_number] then  14
        when QRMODE[:mode_alpha_num] then 13
        when QRMODE[:mode_8bit_byte] then 16
        when QRMODE[:mode_kanji] then 12
        else
          raise QRCodeRunTimeError, "mode: #{mode}"
        end

      else
        raise QRCodeRunTimeError, "type: #{type}"
      end
    end


    def QRUtil.get_lost_point( qr_code )
      modules = qr_code.modules
      module_count = qr_code.module_count
      lost_point = 0

      # level1
      ( 0...module_count ).each do |row|
        ( 0...module_count ).each do |col|
          same_count = 0
          dark = modules[row][col]

          ( -1..1 ).each do |r|
            next if row + r < 0 || module_count <= row + r

            ( -1..1 ).each do |c|
              next if col + c < 0 || module_count <= col + c
              next if r == 0 && c == 0
              if dark == modules[row + r][col + c]
                same_count += 1
              end
            end
          end

          if same_count > 5
            lost_point += (DEMERIT_POINTS_1 + same_count - 5)
          end  
        end
      end

      # level 2
      ( 0...( module_count - 1 ) ).each do |row|
        ( 0...( module_count - 1 ) ).each do |col|
          count = 0
          count = count + 1 if modules[row][col]
          count = count + 1 if modules[row + 1][col]
          count = count + 1 if modules[row][col + 1]
          count = count + 1 if modules[row + 1][col + 1]
          if (count == 0 || count == 4)
            lost_point = lost_point + DEMERIT_POINTS_2
          end
        end  
      end

      # level 3
      ( 0...module_count ).each do |row|
        ( 0...( module_count - 6 ) ).each do |col|
          if modules[row][col] &&
             !modules[row][col + 1] &&
             modules[row][col + 2] &&
             modules[row][col + 3] &&
             modules[row][col + 4] &&
             !modules[row][col + 5] &&
             modules[row][col + 6]
            lost_point += DEMERIT_POINTS_3
          end
        end
      end

      ( 0...module_count ).each do |col|
        ( 0...( module_count - 6 ) ).each do |row|
          if modules[row][col] &&
             !modules[row + 1][col] &&
             modules[row + 2][col] &&
             modules[row + 3][col] &&
             modules[row + 4][col] &&
             !modules[row + 5][col] &&
             modules[row + 6][col]
            lost_point += DEMERIT_POINTS_3
          end
        end
      end

      # level 4
      dark_count = modules.reduce(0) do |sum, col|
         sum + col.count(true)
      end
      ratio = dark_count / (module_count * module_count)
      ratio_delta = (100 * ratio - 50).abs / 5
      lost_point += ratio_delta * DEMERIT_POINTS_4

      return lost_point
    end  

  end

end
