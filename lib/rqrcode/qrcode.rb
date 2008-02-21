module RQRCode

  QRMODE = {
    :mode_number	=> 1 << 0,
    :mode_alpha_num	=> 1 << 1,
    :mode_8bit_byte	=> 1 << 2,
    :mode_kanji		=> 1 << 3
  }

  QRERRORCORRECTLEVEL = {
    :l => 1,
    :m => 0,
    :q => 3,
    :h => 2
  }

  QRMASKPATTERN = {
    :pattern000 => 0,
    :pattern001 => 1,
    :pattern010 => 2,
    :pattern011 => 3,
    :pattern100 => 4,
    :pattern101 => 5,
    :pattern110 => 6,
    :pattern111 => 7
  }

  class QR8bitByte
    attr_reader :mode

    def initialize( data )
      @mode = QRMODE[:mode_8bit_byte]
      @data = data;
    end


    def get_length
      @data.size
    end


    def write( buffer )
      ( 0...@data.size ).each do |i|
        buffer.put( @data[i], 8 )
      end
    end

  end


  class QRCode
    attr_reader :modules

    PAD0 = 0xEC
    PAD1 = 0x11	

    def initialize( options = {} )
      options                   = options.stringify_keys
      @type_number	        = options["size"] || 4
      level		        = options["level"] || "h" 
      @error_correct_level      = QRERRORCORRECTLEVEL[ level.downcase.to_sym ] 
      @modules			= nil
      @module_count		= 0
      @data_cache		= nil
      @data_list		= [] 
    end


    def add_data( data )
      new_data = QR8bitByte.new( data )
      @data_list << new_data
      @data_cache = nil
    end


    def is_dark( row, col )
      if row < 0 || @module_count <= row || col < 0 || @module_count <= col
        raise "#{row},#{col}"
      end

      @modules[row][col]
    end


    def get_module_count
      @module_count
    end


    def make
      make_impl( false, get_best_mask_pattern )
    end


    def make_impl( test, mask_pattern )
      @module_count = @type_number * 4 + 17
      @modules = Array.new( @module_count )

      ( 0...@module_count ).each do |row|
        @modules[row] = Array.new( @module_count )
      end

      setup_position_probe_pattern( 0, 0 )
      setup_position_probe_pattern( @module_count - 7, 0 )
      setup_position_probe_pattern( 0, @module_count - 7 )
      setup_position_adjust_pattern
      setup_timing_pattern
      setup_type_info( test, mask_pattern )
      setup_type_number( test ) if @type_number >= 7

      if @data_cache.nil?
        @data_cache = QRCode.create_data( 
          @type_number, @error_correct_level, @data_list 
        ) 
      end

      map_data( @data_cache, mask_pattern )
    end


    def setup_position_probe_pattern( row, col )
      ( -1..7 ).each do |r|
        next if ( row + r )  <= -1 || @module_count <= ( row + r )
        ( -1..7 ).each do |c|
          next if ( col + c ) <= -1 || @module_count <= ( col + c )
          if 0 <= r && r <= 6 && ( c == 0 || c == 6 ) || 0 <= c && c <= 6 && ( r == 0 || r == 6 ) || 2 <= r && r <= 4 && 2 <= c && c <= 4
            @modules[row + r][col + c] = true;
          else
            @modules[row + r][col + c] = false;
          end
        end
      end
    end


    def get_best_mask_pattern
      min_lost_point = 0
      pattern = 0

      ( 0...8 ).each do |i|
        make_impl( true, i )
        lost_point = QRUtil.get_lost_point( self )

        if i == 0 || min_lost_point > lost_point
          min_lost_point = lost_point
          pattern = i
        end
      end
      pattern
    end


    def setup_timing_pattern
      ( 8...@module_count - 8 ).each do |r|
        next unless @modules[r][6].nil?
        @modules[r][6] = (r % 2 == 0)
      end

      ( 8...@module_count - 8 ).each do |c|
        next unless @modules[6][c].nil?
        @modules[6][c] = (c % 2 == 0)
      end
    end


    def setup_position_adjust_pattern
      pos = QRUtil.get_pattern_position(@type_number)

      ( 0...pos.size ).each do |i|
        ( 0...pos.size ).each do |j|
          row = pos[i]
          col = pos[j]

          next unless @modules[row][col].nil?

          ( -2..2 ).each do |r|
            ( -2..2 ).each do |c|
              if r == -2 || r == 2 || c == -2 || c == 2 || ( r == 0 && c == 0 )
                @modules[row + r][col + c] = true
              else
                @modules[row + r][col + c] = false
              end
            end
          end	
        end
      end
    end


    def setup_type_number( test )
      bits = QRUtil.get_bch_type_number( @type_number )

      ( 0...18 ).each do |i|
        mod = ( !test && ( (bits >> i) & 1) == 1 )
        @modules[ (i / 3).floor ][ i % 3 + @module_count - 8 - 3 ] = mod
      end

      ( 0...18 ).each do |i|
        mod = ( !test && ( (bits >> i) & 1) == 1 )
        @modules[ i % 3 + @module_count - 8 - 3 ][ (i / 3).floor ] = mod
      end
    end


    def setup_type_info( test, mask_pattern )
      data = (@error_correct_level << 3 | mask_pattern)
      bits = QRUtil.get_bch_type_info( data )

      # vertical
      ( 0...15 ).each do |i|
        mod = (!test && ( (bits >> i) & 1) == 1)

        if i < 6
          @modules[i][8] = mod
        elsif i < 8
          @modules[ i + 1 ][8] = mod
        else
          @modules[ @module_count - 15 + i ][8] = mod
        end

      end

      # horizontal
      ( 0...15 ).each do |i|
        mod = (!test && ( (bits >> i) & 1) == 1)

        if i < 8
          @modules[8][ @module_count - i - 1 ] = mod
        elsif i < 9
          @modules[8][ 15 - i - 1 + 1 ] = mod
        else
          @modules[8][ 15 - i - 1 ] = mod
        end
      end

      # fixed module
      @modules[ @module_count - 8 ][8] = !test	
    end


    def map_data( data, mask_pattern )
      inc = -1
      row = @module_count - 1
      bit_index = 7
      byte_index = 0

      ( @module_count - 1 ).step( 1, -2 ) do |col|
        col = col - 1 if col <= 6

        while true do
          ( 0...2 ).each do |c|

            if @modules[row][ col - c ].nil?
              dark = false
              if byte_index < data.size
                dark = (( (data[byte_index]).rszf( bit_index ) & 1) == 1 )
              end
              mask = QRUtil.get_mask( mask_pattern, row, col - c )
              dark = !dark if mask
              @modules[row][ col - c ] = dark
              bit_index -= 1

              if bit_index == -1
                byte_index += 1
                bit_index = 7
              end
            end
          end

          row += inc

          if row < 0 || @module_count <= row
            row -= inc
            inc = -inc
            break
          end
        end
      end	
    end

    def QRCode.create_data( type_number, error_correct_level, data_list )
      rs_blocks = QRRSBlock.get_rs_blocks( type_number, error_correct_level )
      buffer = QRBitBuffer.new

      ( 0...data_list.size ).each do |i|
        data = data_list[i]
        buffer.put( data.mode, 4 )
        buffer.put( 
          data.get_length, QRUtil.get_length_in_bits( data.mode, type_number ) 
          )
        data.write( buffer )	
      end

      total_data_count = 0
      ( 0...rs_blocks.size ).each do |i|
        total_data_count = total_data_count + rs_blocks[i].data_count	
      end

      if buffer.get_length_in_bits > total_data_count * 8
        raise "code length overflow. (#{buffer.get_length_in_bits}>#{total_data_count})"
      end

      if buffer.get_length_in_bits + 4 <= total_data_count * 8
        buffer.put( 0, 4 )
      end

      while buffer.get_length_in_bits % 8 != 0
        buffer.put_bit( false )
      end

      while true
        break if buffer.get_length_in_bits >= total_data_count * 8
        buffer.put( QRCode::PAD0, 8 )
        break if buffer.get_length_in_bits >= total_data_count * 8
        buffer.put( QRCode::PAD1, 8 )
      end

      QRCode.create_bytes( buffer, rs_blocks )
    end


    def QRCode.create_bytes( buffer, rs_blocks )
      offset = 0
      max_dc_count = 0
      max_ec_count = 0
      dcdata = Array.new( rs_blocks.size )
      ecdata = Array.new( rs_blocks.size )

      ( 0...rs_blocks.size ).each do |r|
        dc_count = rs_blocks[r].data_count
        ec_count = rs_blocks[r].total_count - dc_count
        max_dc_count = [ max_dc_count, dc_count ].max
        max_ec_count = [ max_ec_count, ec_count ].max
        dcdata[r] = Array.new( dc_count ) 

        ( 0...dcdata[r].size ).each do |i|
          dcdata[r][i] = 0xff & buffer.buffer[ i + offset ] 
        end

        offset = offset + dc_count
        rs_poly = QRUtil.get_error_correct_polynomial( ec_count )
        raw_poly = QRPolynomial.new( dcdata[r], rs_poly.get_length - 1 )
        mod_poly = raw_poly.mod( rs_poly )
        ecdata[r] = Array.new( rs_poly.get_length - 1 )
        ( 0...ecdata[r].size ).each do |i|
          mod_index = i + mod_poly.get_length - ecdata[r].size
          ecdata[r][i] = mod_index >= 0 ? mod_poly.get( mod_index ) : 0
        end
      end

      total_code_count = 0
      ( 0...rs_blocks.size ).each do |i|
        total_code_count = total_code_count + rs_blocks[i].total_count
      end

      data = Array.new( total_code_count )
      index = 0

      ( 0...max_dc_count ).each do |i|
        ( 0...rs_blocks.size ).each do |r|
          if i < dcdata[r].size
            index += 1
            data[index-1] = dcdata[r][i]			
          end	
        end
      end

      ( 0...max_ec_count ).each do |i|
        ( 0...rs_blocks.size ).each do |r|
          if i < ecdata[r].size
            index += 1
            data[index-1] = ecdata[r][i]			
          end	
        end
      end

      data
    end 

    def to_console
      (0...get_module_count).each do |col|
        tmp = []
        (0...get_module_count).each do |row|
          if is_dark(col,row)
            tmp << "x"
          else
            tmp << " "
          end
        end 
        puts tmp.join
      end
    end

  end


  class QRPolynomial

    def initialize( num, shift )
      raise "#{num.size}/#{shift}" if num.empty?
      offset = 0

      while offset < num.size && num[offset] == 0
        offset = offset + 1
      end

      @num = Array.new( num.size - offset + shift )

      ( 0...num.size - offset ).each do |i|
        @num[i] = num[i + offset]
      end 
    end


    def get( index )
      @num[index]
    end


    def get_length
      @num.size
    end


    def multiply( e )
      num = Array.new( get_length + e.get_length - 1 )

      ( 0...get_length ).each do |i|
        ( 0...e.get_length ).each do |j|
          tmp = num[i + j].nil? ? 0 : num[i + j]
          num[i + j] = tmp ^ QRMath.gexp(QRMath.glog( get(i) ) + QRMath.glog(e.get(j)))
        end
      end

      return QRPolynomial.new( num, 0 )
    end


    def mod( e )
      if get_length - e.get_length < 0
        return self
      end

      ratio = QRMath.glog(get(0)) - QRMath.glog(e.get(0))
      num = Array.new(get_length)

      ( 0...get_length ).each do |i|
        num[i] = get(i)
      end	

      ( 0...e.get_length ).each do |i|
        tmp = num[i].nil? ? 0 : num[i]
        num[i] = tmp ^ QRMath.gexp(QRMath.glog(e.get(i)) + ratio)
      end

      return QRPolynomial.new( num, 0 ).mod(e)
    end 

  end


  class QRRSBlock
    attr_reader :data_count, :total_count

    def initialize( total_count, data_count )
      @total_count = total_count
      @data_count = data_count
    end

    RS_BLOCK_TABLE = [

      # L
      # M
      # Q
      # H

      # 1
      [1, 26, 19],
      [1, 26, 16],
      [1, 26, 13],
      [1, 26, 9],

      # 2
      [1, 44, 34],
      [1, 44, 28],
      [1, 44, 22],
      [1, 44, 16],

      # 3
      [1, 70, 55],
      [1, 70, 44],
      [2, 35, 17],
      [2, 35, 13],

      # 4		
      [1, 100, 80],
      [2, 50, 32],
      [2, 50, 24],
      [4, 25, 9],

      # 5
      [1, 134, 108],
      [2, 67, 43],
      [2, 33, 15, 2, 34, 16],
      [2, 33, 11, 2, 34, 12],

      # 6
      [2, 86, 68],
      [4, 43, 27],
      [4, 43, 19],
      [4, 43, 15],

      # 7		
      [2, 98, 78],
      [4, 49, 31],
      [2, 32, 14, 4, 33, 15],
      [4, 39, 13, 1, 40, 14],

      # 8
      [2, 121, 97],
      [2, 60, 38, 2, 61, 39],
      [4, 40, 18, 2, 41, 19],
      [4, 40, 14, 2, 41, 15],

      # 9
      [2, 146, 116],
      [3, 58, 36, 2, 59, 37],
      [4, 36, 16, 4, 37, 17],
      [4, 36, 12, 4, 37, 13],

      # 10		
      [2, 86, 68, 2, 87, 69],
      [4, 69, 43, 1, 70, 44],
      [6, 43, 19, 2, 44, 20],
      [6, 43, 15, 2, 44, 16]

    ]


    def QRRSBlock.get_rs_blocks( type_number, error_correct_level )
      rs_block = QRRSBlock.get_rs_block_table( type_number, error_correct_level )

      if rs_block.nil?
        raise "bad rs block @ typenumber: #{type_number}/error_correct_level:#{error_correct_level}"
      end

      length = rs_block.size / 3
      list = [] 

      ( 0...length ).each do |i|
        count = rs_block[i * 3 + 0]
        total_count = rs_block[i * 3 + 1]
        data_count = rs_block[i * 3 + 2]

        ( 0...count ).each do |j|
          list << QRRSBlock.new( total_count, data_count )
        end
      end

      list
    end


    def QRRSBlock.get_rs_block_table( type_number, error_correct_level )
      case error_correct_level
      when QRERRORCORRECTLEVEL[:l]
        QRRSBlock::RS_BLOCK_TABLE[(type_number - 1) * 4 + 0]
      when QRERRORCORRECTLEVEL[:m]
        QRRSBlock::RS_BLOCK_TABLE[(type_number - 1) * 4 + 1]
      when QRERRORCORRECTLEVEL[:q]
        QRRSBlock::RS_BLOCK_TABLE[(type_number - 1) * 4 + 2]
      when QRERRORCORRECTLEVEL[:h]
        QRRSBlock::RS_BLOCK_TABLE[(type_number - 1) * 4 + 3]
      else
        nil
      end
    end 

  end


  class QRBitBuffer
    attr_reader :buffer

    def initialize
      @buffer = []
      @length = 0
    end


    def get( index )
      buf_index = (index / 8).floor
      (( (@buffer[buf_index]).rszf(7 - index % 8)) & 1) == 1
    end


    def put( num, length )
      ( 0...length ).each do |i|
        put_bit((((num).rszf(length - i - 1)) & 1) == 1)
      end
    end


    def get_length_in_bits
      @length
    end


    def put_bit( bit )
      buf_index = ( @length / 8 ).floor
      if @buffer.size <= buf_index
        @buffer << 0
      end

      if bit
        @buffer[buf_index] |= ((0x80).rszf(@length % 8))
      end

      @length += 1
    end 

  end


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
      case mask_pattern
      when QRMASKPATTERN[:pattern000]
        (i + j) % 2 == 0
      when QRMASKPATTERN[:pattern001]
        i % 2 == 0
      when QRMASKPATTERN[:pattern010]
        j % 3 == 0
      when QRMASKPATTERN[:pattern011]
        (i + j) % 3 == 0
      when QRMASKPATTERN[:pattern100]
        ((i / 2).floor + (j / 3).floor ) % 2 == 0
      when QRMASKPATTERN[:pattern101]
        (i * j) % 2 + (i * j) % 3 == 0
      when QRMASKPATTERN[:pattern110]
        ( (i * j) % 2 + (i * j) % 3) % 2 == 0
      when QRMASKPATTERN[:pattern111]
        ( (i * j) % 3 + (i + j) % 2) % 2 == 0
      else
        raise "bad mask_pattern: #{mask_pattern}"	
      end
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
        when QRMODE[:mode_number] :	10
        when QRMODE[:mode_alpha_num] : 9
        when QRMODE[:mode_8bit_byte] : 8
        when QRMODE[:mode_kanji] : 8
        else
          raise "mode: #{mode}"
        end

      elsif type < 27

        # 10 -26
        case mode
        when QRMODE[:mode_number] :	12
        when QRMODE[:mode_alpha_num] : 11
        when QRMODE[:mode_8bit_byte] : 16
        when QRMODE[:mode_kanji] : 10
        else
          raise "mode: #{mode}"
        end

      elsif type < 41

        # 27 - 40
        case mode
        when QRMODE[:mode_number] :	14
        when QRMODE[:mode_alpha_num] : 13
        when QRMODE[:mode_8bit_byte] : 16
        when QRMODE[:mode_kanji] : 12
        else
          raise "mode: #{mode}"
        end

      else
        raise "type: #{type}"
      end
    end


    def QRUtil.get_lost_point( qr_code )
      module_count = qr_code.get_module_count
      lost_point = 0

      # level1
      ( 0...module_count ).each do |row|
        ( 0...module_count ).each do |col|
          same_count = 0
          dark = qr_code.is_dark( row, col )

          ( -1..1 ).each do |r|
            next if row + r < 0 || module_count <= row + r

            ( -1..1 ).each do |c|
              next if col + c < 0 || module_count <= col + c
              next if r == 0 && c == 0
              if dark == qr_code.is_dark( row + r, col + c )
                same_count += 1
              end
            end
          end

          if same_count > 5
            lost_point += (3 + same_count - 5)
          end	
        end
      end

      # level 2
      ( 0...( module_count - 1 ) ).each do |row|
        ( 0...( module_count - 1 ) ).each do |col|
          count = 0
          count = count + 1 if qr_code.is_dark( row, col )
          count = count + 1 if qr_code.is_dark( row + 1, col )
          count = count + 1 if qr_code.is_dark( row, col + 1 )
          count = count + 1 if qr_code.is_dark( row + 1, col + 1 )
          lost_point = lost_point + 3 if (count == 0 || count == 4)	
        end	
      end

      # level 3
      ( 0...module_count ).each do |row|
        ( 0...( module_count - 6 ) ).each do |col|
          if qr_code.is_dark( row, col ) && !qr_code.is_dark( row, col + 1 ) && qr_code.is_dark( row, col + 2 ) && qr_code.is_dark( row, col + 3 ) && qr_code.is_dark( row, col + 4 ) && !qr_code.is_dark( row, col + 5 ) && qr_code.is_dark( row, col + 6 )
            lost_point = lost_point + 40
          end
        end
      end

      ( 0...module_count ).each do |col|
        ( 0...( module_count - 6 ) ).each do |row|
          if qr_code.is_dark(row, col) && !qr_code.is_dark(row + 1, col) &&  qr_code.is_dark(row + 2, col) &&  qr_code.is_dark(row + 3, col) &&  qr_code.is_dark(row + 4, col) && !qr_code.is_dark(row + 5, col) &&  qr_code.is_dark(row + 6, col)
            lost_point = lost_point + 40
          end
        end
      end

      # level 4
      dark_count = 0

      ( 0...module_count ).each do |col|
        ( 0...module_count ).each do |row|
          if qr_code.is_dark(row, col)
            dark_count = dark_count + 1
          end	
        end
      end

      ratio = (100 * dark_count / module_count / module_count - 50).abs / 5
      lost_point = lost_point * 10

      lost_point			
    end	

  end


  class QRMath

    module_eval { 
      exp_table = Array.new(256)
      log_table = Array.new(256)

      ( 0...8 ).each do |i|
        exp_table[i] = 1 << i
      end

      ( 8...256 ).each do |i|
        exp_table[i] = exp_table[i - 4] \
          ^ exp_table[i - 5] \
          ^ exp_table[i - 6] \
          ^ exp_table[i - 8]
      end

      ( 0...255 ).each do |i|
        log_table[exp_table[i] ] = i
      end

      EXP_TABLE = exp_table 
      LOG_TABLE = log_table 
    }

    class << self

      def glog(n)
        raise "glog(#{n})" if ( n < 1 )
        LOG_TABLE[n]
      end


      def gexp(n)
        while n < 0
          n = n + 255
        end

        while n >= 256
          n = n - 255
        end

        EXP_TABLE[n]
      end

    end

  end


end
