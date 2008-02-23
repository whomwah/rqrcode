#!/usr/bin/env ruby

#--
# Copyright 2004 by Duncan Robertson (duncan@whomwah.com).
# All rights reserved.

# Permission is granted for use, copying, modification, distribution,
# and distribution of modified versions of this work as long as the
# above copyright notice is included.
#++

module RQRCode

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

end
