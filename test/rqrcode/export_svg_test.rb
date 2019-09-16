require 'test_helper'
require 'rqrcode/data'

describe 'Export::SVG' do
  it 'must respond_to svg' do
    RQRCode::QRCode.new('qrcode').must_respond_to :as_svg
  end

  it 'must export to svg' do
    RQRCode::QRCode.new('qrcode').as_svg.must_equal(AS_SVG)
  end

  describe "options" do
    it 'has standalone option true by default' do
      doc = RQRCode::QRCode.new('qrcode').as_svg
      # For now we do very naive pattern matching. The alternative is to
      # include a librariry for parsing XML, like nokogiri. That is a big
      # change for such a small test, though.
      assert_match %r{<\?xml.*standalone="yes"}, doc
      assert_match %r{<svg.*>}, doc
      assert_match %r{</svg>}, doc
    end

    it 'omits surrounding XML when `standalone` is `false`' do
      doc = RQRCode::QRCode.new('qrcode').as_svg(standalone: false)
      # For now we do very naive pattern matching. The alternative is to
      # include a librariry for parsing XML, like nokogiri. That is a big
      # change for such a small test, though.
      refute_match %r{<\?xml.*standalone="yes"}, doc
      refute_match %r{<svg.*>}, doc
      refute_match %r{</svg>}, doc
    end
  end
end
