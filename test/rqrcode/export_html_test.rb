require 'test_helper'

describe 'Export::HTML' do
  it 'must respond_to html' do
    RQRCode::QRCode.new('html').must_respond_to :as_html
  end

  it 'must export to html' do
    RQRCode::QRCode.new('html').as_html.must_equal(AS_HTML)
  end
end
