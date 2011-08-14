#!/usr/bin/env ruby

#--
# Copyright 2008 by Duncan Robertson (duncan@whomwah.com).
# All rights reserved.

# Permission is granted for use, copying, modification, distribution,
# and distribution of modified versions of this work as long as the
# above copyright notice is included.
#++

module RQRCode #:nodoc:

  QRMODE = {
    :mode_number        => 1 << 0,
    :mode_alpha_numk    => 1 << 1,
    :mode_8bit_byte     => 1 << 2,
    :mode_kanji         => 1 << 3
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

  QRMASKCOMPUTATIONS = [
        Proc.new { |i,j| (i + j) % 2 == 0 },
        Proc.new { |i,j| i % 2 == 0 },
        Proc.new { |i,j| j % 3 == 0 },
        Proc.new { |i,j| (i + j) % 3 == 0 },
        Proc.new { |i,j| ((i / 2).floor + (j / 3).floor) % 2 == 0 },
        Proc.new { |i,j| (i * j) % 2 + (i * j) % 3 == 0 },
        Proc.new { |i,j| ((i * j) % 2 + (i * j) % 3) % 2 == 0 },
        Proc.new { |i,j| ((i * j) % 3 + (i + j) % 2) % 2 == 0 },
  ]

  QRPOSITIONPATTERNLENGTH = (7 + 1) * 2 + 1
  QRFORMATINFOLENGTH = 15

  # StandardErrors

  class QRCodeArgumentError < ArgumentError; end
  class QRCodeRunTimeError < RuntimeError; end

  # == Creation
  #
  # QRCode objects expect only one required constructor parameter
  # and an optional hash of any other. Here's a few examples: 
  #
  #  qr = RQRCode::QRCode.new('hello world')
  #  qr = RQRCode::QRCode.new('hello world', :size => 1, :level => :m ) 
  #

  class QRCode
    attr_reader :modules, :module_count

    PAD0 = 0xEC
    PAD1 = 0x11  

    # Expects a string to be parsed in, other args are optional 
    #
    #   # string - the string you wish to encode 
    #   # size   - the size of the qrcode (default 4)
    #   # level  - the error correction level, can be:
    #      * Level :l 7%  of code can be restored
    #      * Level :m 15% of code can be restored
    #      * Level :q 25% of code can be restored
    #      * Level :h 30% of code can be restored (default :h) 
    #
    #   qr = RQRCode::QRCode.new('hello world', :size => 1, :level => :m ) 
    #

    def initialize( string, *args )
      if !string.is_a? String
        raise QRCodeArgumentError, "The passed data is #{string.class}, not String"
      end

      options               = args.extract_options!
      level                 = (options[:level] || :h).to_sym
      size                  = options[:size] || 4

      if !QRERRORCORRECTLEVEL.has_key?(level)
        raise QRCodeArgumentError, "Unknown error correction level `#{level.inspect}`"
      end

      @data                 = string
      @error_correct_level  = QRERRORCORRECTLEVEL[level]
      @version              = size
      @module_count         = @version * 4 + QRPOSITIONPATTERNLENGTH
      @modules              = Array.new( @module_count )
      @data_list            = QR8bitByte.new( @data )
      @data_cache           = nil

      self.make
    end

    # <tt>is_dark</tt> is called with a +col+ and +row+ parameter. This will
    # return true or false based on whether that coordinate exists in the 
    # matrix returned. It would normally be called while iterating through
    # <tt>modules</tt>. A simple example would be:
    #   
    #  instance.is_dark( 10, 10 ) => true
    #

    def is_dark( row, col )
      if !row.between?(0, @module_count - 1) || !col.between?(0, @module_count - 1)
        raise QRCodeRunTimeError, "Invalid row/column pair: #{row}, #{col}"
      end
      @modules[row][col]
    end

    alias dark? is_dark

    # This is a public method that returns the QR Code you have
    # generated as a string. It will not be able to be read
    # in this format by a QR Code reader, but will give you an
    # idea if the final outout. It takes two optional args
    # +:true+ and +:false+ which are there for you to choose
    # how the output looks. Here's an example of it's use:
    #
    #  instance.to_s =>
    #  xxxxxxx x  x x   x x  xx  xxxxxxx
    #  x     x  xxx  xxxxxx xxx  x     x
    #  x xxx x  xxxxx x       xx x xxx x
    #
    #  instance._to_s( :true => 'E', :false => 'Q') =>
    #  EEEEEEEQEQQEQEQQQEQEQQEEQQEEEEEEE
    #  EQQQQQEQQEEEQQEEEEEEQEEEQQEQQQQQE
    #  EQEEEQEQQEEEEEQEQQQQQQQEEQEQEEEQE
    #

    def to_s( *args )
      options                = args.extract_options!
      row                    = options[:true] || 'x' 
      col                    = options[:false] || ' ' 

      res = []

      @modules.each_index do |c|
        tmp = []
        @modules.each_index do |r|
          if is_dark(c,r)
            tmp << row 
          else
            tmp << col 
          end
        end 
        res << tmp.join
     end
      res.join("\n")
    end

    protected

    def make #:nodoc:
      prepare_common_patterns
      make_impl( false, get_best_mask_pattern )
    end

    private

    def prepare_common_patterns
        @modules.map! { |row| Array.new(@module_count) }

        place_position_probe_pattern(0, 0)
        place_position_probe_pattern(@module_count - 7, 0)
        place_position_probe_pattern(0, @module_count - 7)
        place_position_adjust_pattern
        place_timing_pattern

        @common_patterns = @modules.map(&:clone)
    end

    def make_impl( test, mask_pattern ) #:nodoc:
      @modules = @common_patterns.map(&:clone)

      place_format_info(test, mask_pattern)
      place_version_info(test) if @version >= 7

      if @data_cache.nil?
        @data_cache = QRCode.create_data( 
          @version, @error_correct_level, @data_list
        ) 
      end

      map_data( @data_cache, mask_pattern )
    end


    def place_position_probe_pattern( row, col ) #:nodoc:
      (-1..7).each do |r|
        next if !(row + r).between?(0, @module_count - 1)

        (-1..7).each do |c|
          next if !(col + c).between?(0, @module_count - 1)

          is_vert_line = (r.between?(0, 6) && (c == 0 || c == 6))
          is_horiz_line = (c.between?(0, 6) && (r == 0 || r == 6))
          is_square = r.between?(2,4) && c.between?(2, 4)

          is_part_of_probe = is_vert_line || is_horiz_line || is_square
          @modules[row + r][col + c] = is_part_of_probe
        end
      end
    end


    def get_best_mask_pattern #:nodoc:
      min_lost_point = 0
      pattern = 0

      ( 0...8 ).each do |i|
        make_impl( true, i )
        lost_point = QRUtil.get_lost_points(self.modules)

        if i == 0 || min_lost_point > lost_point
          min_lost_point = lost_point
          pattern = i
        end
      end
      pattern
    end


    def place_timing_pattern #:nodoc:
      ( 8...@module_count - 8 ).each do |i|
        @modules[i][6] = @modules[6][i] = i % 2 == 0 
      end
    end


    def place_position_adjust_pattern #:nodoc:
      positions = QRUtil.get_pattern_positions(@version)

      positions.each do |row|
        positions.each do |col|
          next unless @modules[row][col].nil?

          ( -2..2 ).each do |r|
            ( -2..2 ).each do |c|
              is_part_of_pattern = (r.abs == 2 || c.abs == 2 || ( r == 0 && c == 0 ))
              @modules[row + r][col + c] = is_part_of_pattern
            end
          end  
        end
      end
    end


    def place_version_info(test) #:nodoc:
      bits = QRUtil.get_bch_version(@version)

      ( 0...18 ).each do |i|
        mod = ( !test && ( (bits >> i) & 1) == 1 )
        @modules[ (i / 3).floor ][ i % 3 + @module_count - 8 - 3 ] = mod
        @modules[ i % 3 + @module_count - 8 - 3 ][ (i / 3).floor ] = mod
      end
    end


    def place_format_info(test, mask_pattern) #:nodoc:
      data = (@error_correct_level << 3 | mask_pattern)
      bits = QRUtil.get_bch_format_info(data)

      QRFORMATINFOLENGTH.times do |i|
        mod = (!test && ( (bits >> i) & 1) == 1)

        # vertical
        if i < 6
          row = i
        elsif i < 8
          row = i + 1
        else
          row = @module_count - 15 + i
        end
        @modules[row][8] = mod

        # horizontal
        if i < 8
          col = @module_count - i - 1
        elsif i < 9
          col = 15 - i - 1 + 1
        else
          col = 15 - i - 1
        end
        @modules[8][col] = mod
      end

      # fixed module
      @modules[ @module_count - 8 ][8] = !test  
    end


    def map_data( data, mask_pattern ) #:nodoc:
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
              if byte_index < data.size && !data[byte_index].nil?
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

    def QRCode.count_max_data_bits(rs_blocks)
      max_data_bytes = rs_blocks.reduce(0) do |sum, rs_block|
        sum + rs_block.data_count
      end

      return max_data_bytes * 8
    end

    def QRCode.create_data(version, error_correct_level, data_list) #:nodoc:
      rs_blocks = QRRSBlock.get_rs_blocks(version, error_correct_level)
      buffer = QRBitBuffer.new

      data = data_list
      buffer.put( data.mode, 4 )
      buffer.put( 
        data.get_length, QRUtil.get_length_in_bits(data.mode, version)
      )
      data.write( buffer )  

      max_data_bits = QRCode.count_max_data_bits(rs_blocks)

      if buffer.get_length_in_bits > max_data_bits
        raise QRCodeRunTimeError, 
          "code length overflow. (#{buffer.get_length_in_bits}>#{max_data_bits})"
      end

      if buffer.get_length_in_bits + 4 <= max_data_bits
        buffer.put( 0, 4 )
      end

      while buffer.get_length_in_bits % 8 != 0
        buffer.put_bit( false )
      end

      while true
        break if buffer.get_length_in_bits >= max_data_bits
        buffer.put( QRCode::PAD0, 8 )
        break if buffer.get_length_in_bits >= max_data_bits
        buffer.put( QRCode::PAD1, 8 )
      end

      QRCode.create_bytes( buffer, rs_blocks )
    end


    def QRCode.create_bytes( buffer, rs_blocks ) #:nodoc:
      offset = 0
      max_dc_count = 0
      max_ec_count = 0
      dcdata = Array.new( rs_blocks.size )
      ecdata = Array.new( rs_blocks.size )

      rs_blocks.each_with_index do |rs_block, r|
        dc_count = rs_block.data_count
        ec_count = rs_block.total_count - dc_count
        max_dc_count = [ max_dc_count, dc_count ].max
        max_ec_count = [ max_ec_count, ec_count ].max

        dcdata_block = Array.new(dc_count)
        dcdata_block.size.times do |i|
          dcdata_block[i] = 0xff & buffer.buffer[ i + offset ]
        end
        dcdata[r] = dcdata_block

        offset = offset + dc_count
        rs_poly = QRUtil.get_error_correct_polynomial( ec_count )
        raw_poly = QRPolynomial.new( dcdata[r], rs_poly.get_length - 1 )
        mod_poly = raw_poly.mod( rs_poly )

        ecdata_block = Array.new(rs_poly.get_length - 1)
        ecdata_block.size.times do |i|
          mod_index = i + mod_poly.get_length - ecdata_block.size
          ecdata_block[i] = mod_index >= 0 ? mod_poly.get( mod_index ) : 0
        end
        ecdata[r] = ecdata_block
      end

      total_code_count = rs_blocks.reduce(0) do |sum, rs_block|
        sum + rs_block.total_count
      end

      data = Array.new( total_code_count )
      index = 0

      max_dc_count.times do |i|
        rs_blocks.size.times do |r|
          if i < dcdata[r].size
            data[index] = dcdata[r][i]
            index += 1
          end  
        end
      end

      max_ec_count.times do |i|
        rs_blocks.size.times do |r|
          if i < ecdata[r].size
            data[index] = ecdata[r][i]
            index += 1
          end  
        end
      end

      data
    end 

  end

end
