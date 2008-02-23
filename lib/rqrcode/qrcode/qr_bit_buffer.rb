#!/usr/bin/env ruby

#--
# Copyright 2004 by Duncan Robertson (duncan@whomwah.com).
# All rights reserved.

# Permission is granted for use, copying, modification, distribution,
# and distribution of modified versions of this work as long as the
# above copyright notice is included.
#++

module RQRCode

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

end
