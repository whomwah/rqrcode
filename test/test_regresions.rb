# encoding: utf-8
require "test/unit"

# fix for require_relative in < 1.9
unless Kernel.respond_to?(:require_relative)
  module Kernel
    def require_relative(path)
      require File.join(File.dirname(caller[0]), path.to_str)
    end
  end
end

require_relative "../lib/rqrcode"
class RegresionTests < Test::Unit::TestCase
  
  # Rs block information was incomplete.
  def test_code_length_overflow_bug
    RQRCode::QRCode.new('s' * 220)
    RQRCode::QRCode.new('s' * 195)  
  end
end