module RQRCode

  NUMERIC = ['0','1','2','3','4','5','6','7','8','9'].freeze

  class QRNumeric
    attr_reader :mode

    def initialize( data )
      @mode = QRMODE[:mode_number]

      raise QRCodeArgumentError, "Not a numeric string `#{data}`" unless QRNumeric.valid_data?(data)

      @data = data;
    end


    def get_length
      @data.size
    end

    def self.valid_data? data
      data.each_char do |s|
        return false if NUMERIC.index(s).nil?
      end
      true
    end


    def write( buffer)
      buffer.numeric_encoding_start(get_length)

      (@data.size).times do |i|
        if i % 2 == 0
          if i == (@data.size - 1)
            value = NUMERIC.index(@data[i])
            buffer.put( value, 6 )
          else
            value = (NUMERIC.index(@data[i]) * 45) + NUMERIC.index(@data[i+1])
            buffer.put( value, 11 )
          end
        end
      end


    end
  end
end
