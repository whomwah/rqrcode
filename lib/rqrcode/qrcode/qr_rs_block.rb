#!/usr/bin/env ruby

#--
# Copyright 2004 by Duncan Robertson (duncan@whomwah.com).
# All rights reserved.

# Permission is granted for use, copying, modification, distribution,
# and distribution of modified versions of this work as long as the
# above copyright notice is included.
#++

module RQRCode #:nodoc:

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


    def QRRSBlock.get_rs_blocks( type_no, error_correct_level )
      rs_block = QRRSBlock.get_rs_block_table( type_no, error_correct_level )

      if rs_block.nil?
        raise QRCodeRunTimeError,
          "bad rsblock @ typeno: #{type_no}/error_correct_level:#{error_correct_level}"
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

end
