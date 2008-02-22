# file: pureimage.rb
#
# Copyright (C) 2005 NISHIMOTO Keisuke.

require 'iconv'
require 'zlib'

module PureImage

######################################################################
# Font.
######################################################################

class CharImage

  attr_reader :pixels, :width

  def initialize(width, pixels)
    @width  = width
    @pixels = pixels
  end

end

# Font file format:
#
# class Location
#   short code
#   int   offset
# end
#
# class CharImage
#   short width
#   byte[] pixels
# end
#
# class Font
#   int length
#   short height
#   short ascent
#   short descent
#   Location[] locations
#   CharImage[] images
# end

class Font

  def initialize(file)
    begin
      @iconv = $KCODE != 'NONE' ? Iconv.new('UTF-8', $KCODE) : nil
      inp = File.new(file, "r")
      inp.binmode
      @file = file
    rescue
      raise "Cannot read font file: " + file
    end
    begin
      length   = read_int(inp)
      @height  = read_short(inp)
      @ascent  = read_short(inp)
      @descent = read_short(inp)
      @locations = Hash.new
      for i in 0..(length - 1)
        code = read_short(inp)
        offset = read_int(inp)
        @locations[code] = offset
      end
      @font = Hash.new()
      read_char_image(0x20)
    rescue
      raise "Cannot read font file: " + file
    ensure
      inp.close
    end
  end

  def image(code)
    char_image = @font[code]
    if char_image == nil then
      begin
        char_image = read_char_image(code)
      end
    end
    return char_image != nil ? char_image : @font[0x20]
  end

  def string_width(str)
    unicode = to_unicode(str)
    width = 0
    for i in 0..(unicode.length - 1)
      width += width(unicode[i])
    end
    return width
  end

  def width(code)
    return image(code).width
  end

  def height
    return @height
  end

  def ascent
    return @ascent
  end

  def descent
    return @descent
  end

  def to_unicode(str)
    # 0000 0000-0000 007F | 0xxxxxxx
    # 0000 0080-0000 07FF | 110xxxxx 10xxxxxx (1)
    # 0000 0800-0000 FFFF | 1110xxxx 10xxxxxx 10xxxxxx (2-3)
    # 0001 0000-0010 FFFF | 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx (4-6)
    unicode = Array.new
    mode = 0; code = 0
    utf8_str = @iconv != nil ? @iconv.iconv(str) : str
    utf8_str.each_byte {|c|
      if mode == 0 then
        if c <= 0x7f then
          code = c
          unicode.push(code)
        elsif c <= 0xdf then
          code = c & 0x1f
          mode = 1
        elsif c <= 0xef then
          code = c & 0xf
          mode = 2
        elsif c < 0xf7 then
          code = c & 0x7
          mode = 4
        end
      elsif mode == 1 then
        code = code << 6 | (c & 0x3f)
        mode = 0
        unicode.push(code);
      elsif mode == 2 then
        code = code << 6 | (c & 0x3f)
        mode = 3
      elsif mode == 3 then
        code = code << 6 | (c & 0x3f)
        mode = 0
        unicode.push(code)
      elsif mode == 4 then
        code = code << 6 | (c & 0x3f)
        mode = 5
      elsif mode == 5 then
        code = code << 6 | (c & 0x3f)
        mode = 5
      elsif mode == 5 then
        code = code << 6 | (c & 0x3f)
        mode = 0
        unicode.push(code)
      end
    }
    return unicode
  end

  def read_char_image(code)
    begin
      inp = File.new(@file, "r")
      inp.binmode
    rescue
      raise "Cannot read font file: " + file
    end
    begin
      offset = @locations[code]
      if offset == nil then
        return nil
      end
      inp.seek(offset)
      width  = read_short(inp)
      pixels = Array.new(width * @height)
      for i in 0..(pixels.length - 1)
        pixels[i] = inp.getc
      end
      @font[code] = CharImage.new(width, pixels)
    rescue
      raise "Cannot read font file: " + @file
    ensure
      inp.close
    end
  end
  private :read_char_image

  def read_short(inp)
    return (inp.getc & 0xff) << 8 | (inp.getc & 0xff)
  end
  private :read_short

  def read_int(inp)
    return (inp.getc & 0xff) << 24 | (inp.getc & 0xff) << 16 \
         | (inp.getc & 0xff) << 8 | (inp.getc & 0xff)
  end
  private :read_int

end

######################################################################
# Image.
######################################################################

class Image

  attr_reader :width, :height, :enable_alpha, :pixels
  attr_accessor :color, :alpha, :font

  def initialize(width, height, c = 0xffffff, enable_alpha = false)
    size = width * height
    @width = width
    @height = height
    @enable_alpha = enable_alpha
    @color = 0x000000
    @alpha = 255
    @pixels = Array.new(size)
    r = (c >> 16) & 0xff
    g = (c >> 8) & 0xff
    b = c & 0xff
    a = 0xff
    @pixels.fill([r, g, b, a])
  end

  def get(x, y)
    if x >= 0 && x < @width && y >= 0 && y < @height then
      return @pixels[x + y * @width]
    else
      return 0
    end
  end

  def set(x, y, c)
    if x >= 0 && x < @width && y >= 0 && y < @height then
      @pixels[x + y * @width] = c
    end
  end

  def draw_string(str, x, y, c = @color, a = @alpha)
    red   = (c >> 16) & 0xff
    green = (c >> 8) & 0xff
    blue  = c & 0xff
    height = @font.height
    ascent = @font.ascent
    unicode_str = @font.to_unicode(str)
    unicode_str.each {|code|
      char_image = @font.image(code)
      width  = char_image.width
      pixels = char_image.pixels
      index = 0
      for j in 0..(height - 1)
        y0 = y - ascent + j
        for i in 0..(width - 1)
          font_alpha = pixels[index]
          if font_alpha > 0 then
            x0 = x + i
            col = get(x0, y0)
            alpha = (a * font_alpha / 255).to_i
            rev_alpha = 255 - alpha
            r = (col[0] * rev_alpha + red * alpha) / 255
            r = r <= 255 ? r.to_i : 255
            g = (col[1] * rev_alpha + green * alpha) / 255
            g = g <= 255 ? g.to_i : 255
            b = (col[2] * rev_alpha + blue * alpha) / 255
            b = b <= 255 ? b.to_i : 255
            col = [r, g, b, col[3]]
            set(x0, y0, col)
          end
          index += 1
        end
      end
      x += width
    }
  end

  def draw_line(x0, y0, x1, y1, c = @color, a = @alpha)
    if a <= 0 then return end
    red   = (c >> 16) & 0xff
    green = (c >> 8) & 0xff
    blue  = c & 0xff
    dx = (x1 - x0).abs
    dy = (y1 - y0).abs
    if(dx >= dy) then
      # dx >= dy
      if x0 > x1 then
        tmp = x0; x0 = x1; x1 = tmp
        tmp = y0; y0 = y1; y1 = tmp
      end
      y = y0; tmp = (dx / 2).to_i; iy = y0 < y1 ? 1 : -1
      if a == 255 then
        for x in x0..x1
          col = get(x, y)
          set(x, y, [red, green, blue, col[3]])
          tmp -= dy
          if tmp < 0 then
            y += iy
            tmp += dx
          end
        end
      else
        alpha = a
        rev_alpha = 255 - a
        for x in x0..x1
          col = get(x, y)
          r = (col[0] * rev_alpha + red * alpha) / 255
          r = r <= 255 ? r.to_i : 255
          g = (col[1] * rev_alpha + green * alpha) / 255
          g = g <= 255 ? g.to_i : 255
          b = (col[2] * rev_alpha + blue * alpha) / 255
          b = b <= 255 ? b.to_i : 255
          set(x, y, [r, g, b, col[3]])
          tmp -= dy
          if tmp < 0 then
            y += iy
            tmp += dx
          end
        end
      end
    else
      # dx < dy
      if y0 > y1 then
        tmp = x0; x0 = x1; x1 = tmp
        tmp = y0; y0 = y1; y1 = tmp
      end
      x = x0; tmp = (dy / 2).to_i; ix = x0 < x1 ? 1 : -1
      if a == 255 then
        for y in y0..y1
          col = get(x, y)
          set(x, y, [red, green, blue, col[3]])
          tmp -= dx
          if tmp < 0 then
            x += ix
            tmp += dy
          end
        end
      else
        alpha = a
        rev_alpha = 255 - a
        for y in y0..y1
          col = get(x, y)
          r = (col[0] * rev_alpha + red * alpha) / 255
          r = r <= 255 ? r.to_i : 255
          g = (col[1] * rev_alpha + green * alpha) / 255
          g = g <= 255 ? g.to_i : 255
          b = (col[2] * rev_alpha + blue * alpha) / 255
          b = b <= 255 ? b.to_i : 255
          set(x, y, [r, g, b, col[3]])
          tmp -= dx
          if tmp < 0 then
            x += ix
            tmp += dy
          end
        end
      end
    end
  end

  def draw_hline(x, y, width, c = @color, a = @alpha)
    if y < 0 || y >= @height || @width <= 0 || a <= 0 then return end
    x0 = x
    x1 = x + width
    x0 = x0 >= 0 ? x0 : 0
    x0 = x0 < @width ? x0 : -1
    x1 = x1 >= 0 ? x1 : -1
    x1 = x1 < @width ? x1 : @width - 1
    if x0 < 0 || x1 < 0 then return end
    i0 = x0 + y * @width
    i1 = x1 + y * @width
    red   = (c >> 16) & 0xff
    green = (c >> 8) & 0xff
    blue  = c & 0xff
    if a == 255 then
      for i in i0..i1
        @pixels[i] = [red, green, blue, @pixels[i][3]]
      end
    else
      alpha = a
      rev_alpha = 255 - a
      for i in i0..i1
        c = @pixels[i]
        r = c[0]
        g = c[1]
        b = c[2]
        a = c[3]
        r = (rev_alpha * r + alpha * red) / 255
        r = r <= 255 ? r.to_i : 255
        g = (rev_alpha * g + alpha * green) / 255
        g = g <= 255 ? g.to_i : 255
        b = (rev_alpha * b + alpha * blue) / 255
        b = b <= 255 ? b.to_i : 255
        @pixels[i] = [r, g, b, a]
      end
    end
  end

  def draw_vline(x, y, height, c = @color, a = @alpha)
    if x < 0 || x >= @width || @height <= 0 || a == 0 then return end
    y0 = y
    y1 = y + height
    y0 = y0 >= 0 ? y0 : 0
    y0 = y0 < @height ? y0 : -1
    y1 = y1 >= 0 ? y1 : -1
    y1 = y1 < @height ? y1 : @height - 1
    if y0 < 0 || y1 < 0 then return end
    i = x + y0 * @width
    red   = (c >> 16) & 0xff
    green = (c >> 8) & 0xff
    blue  = c & 0xff
    if a == 255 then
      for y in y0..y1
        @pixels[i] = [red, green, blue, @pixels[i][3]]
        i += @width
      end
    else
      alpha = a
      rev_alpha = 255 - a
      for y in y0..y1
        c = @pixels[i]
        r = c[0]
        g = c[1]
        b = c[2]
        a = c[3]
        r = (rev_alpha * r + alpha * red) / 255
        r = r <= 255 ? r.to_i : 255
        g = (rev_alpha * g + alpha * green) / 255
        g = g <= 255 ? g.to_i : 255
        b = (rev_alpha * b + alpha * blue) / 255
        b = b <= 255 ? b.to_i : 255
        @pixels[i] = [r, g, b, a]
        i += @width
      end
    end
  end

  def draw_rect(x, y, width, height, c = @color, a = @alpha)
    x0 = x;         y0 = y
    x1 = x + width; y1 = y + height
    draw_hline(x0, y0, width, c, a)
    draw_hline(x0, y1, width, c, a)
    draw_vline(x0, y0 + 1, height - 2, c, a)
    draw_vline(x1, y0 + 1, height - 2, c, a)
  end

  def fill_rect(x, y, width, height, c = @color, a = @alpha)
    x0 = x; x1 = x + width
    y0 = y; y1 = y + height
    for y in y0..y1
      draw_hline(x0, y, width, c, a)
    end
  end

  def fill_polygon(xa, ya, c = @color, a = @alpha)
    point_count = xa.length <= ya.length ? xa.length : ya.length
    if point_count <= 2 then return end
    if xa[0] != xa[point_count - 1] || ya[0] != ya[point_count - 1] then
      xa.push(xa[0]); ya.push(ya[0])
      point_count += 1
    end
    line_count = point_count - 1
    ymin = ya[0]; ymax = ya[0]
    for i in 0..(point_count - 1)
      ymin = ymin > ya[i] ? ya[i] : ymin
      ymax = ymax < ya[i] ? ya[i] : ymax
    end
    x0a = Array.new(line_count); y0a = Array.new(line_count)
    x1a = Array.new(line_count); y1a = Array.new(line_count)
    for i in 0..(line_count - 1)
      x0 = xa[i];     y0 = ya[i]
      x1 = xa[i + 1]; y1 = ya[i + 1]
      if(y0 > y1) then
        tmp = x0; x0 = x1; x1 = tmp
        tmp = y0; y0 = y1; y1 = tmp
      end
      x0a[i] = x0; y0a[i] = y0
      x1a[i] = x1; y1a[i] = y1
    end
    xpa = Array.new
    for y in ymin..ymax
      xpa.clear
      for i in 0..(line_count - 1)
        x0 = x0a[i]; y0 = y0a[i]
        x1 = x1a[i]; y1 = y1a[i]
        if y >= y0 && y < y1 && y0 != y1 then
          x = x0 + (y - y0) * (x1 - x0) / (y1 - y0)
          xpa.push(x)
        end
      end
      xpa.sort!
      for i in 0..(xpa.length / 2 - 1)
        x0 = xpa[i * 2]; x1 = xpa[i * 2 + 1]
        w = x1 - x0
        draw_hline(x0, y, w, c, a)
      end
    end
  end

  def draw(shape, c = @color, a = @alpha)
    y_min = shape.y_min
    y_max = shape.y_max
    for y in y_min..y_max
      xs = shape.xpoints(y)
      xs.sort!
      for i in 0..(xs.length / 2 - 1)
        x0 = xs[i * 2]; x1 = xs[i * 2 + 1]
        w = x1 - x0
        draw_hline(x0.to_i, y.to_i, w.to_i, c, a)
      end
    end
  end

  def draw_image(image, sx, sy, width, height, untialiasing = false)
    imageW = image.width
    imageH = image.height
    xsa = Array.new(width)
    xea = Array.new(width)
    ysa = Array.new(height)
    yea = Array.new(height)
    for i in 0..(width - 1)
      xsa[i] = i * imageW / width
    end
    for i in 0..(width - 2)
      xea[i] = xsa[i + 1] - 1
    end
    xea[width - 1] = imageW - 1
    for i in 0..(height - 1)
      ysa[i] = i * imageH / height
    end
    for i in 0..(height - 2)
      yea[i] = ysa[i + 1] - 1
    end
    yea[height - 1] = imageH - 1
    for iy in 0..(height - 1)
      for ix in 0..(width - 1)
        xs = xsa[ix]
        xe = xea[ix]
        ys = ysa[iy]
        ye = yea[iy]
        if untialiasing then
          area = (xe - xs + 1) * (ye - ys + 1)
          imageColor = [0, 0, 0, 0]
          for j in ys..ye
            for i in xs..xe
              c = image.get(i, j)
              imageColor[0] += c[0]
              imageColor[1] += c[1]
              imageColor[2] += c[2]
              imageColor[3] += c[3]
            end
          end
          imageColor[0] /= area
          imageColor[1] /= area
          imageColor[2] /= area
          imageColor[3] /= area
        else
          imageColor = image.get((xs + xe) / 2, (ys + ye) / 2)
        end
        a = imageColor[3]
        if a == 255 then
          set(sx + ix, sy + iy, imageColor);
        elsif a > 0
          ra = 255 - a
          color = get(sx + ix, sy + iy)
          color[0] = (a * imageColor[0] + ra * color[0]) / 255
          color[1] = (a * imageColor[1] + ra * color[1]) / 255
          color[2] = (a * imageColor[2] + ra * color[2]) / 255
          set(sx + ix, sy + iy, color);
        end
      end
    end
  end

end

######################################################################
# Shape
######################################################################

class Shape
  def x_min
  end
  def x_max
  end
  def y_min
    return 0
  end
  def y_max
    return 0
  end
  def xpoints(y)
    return []
  end
end

######################################################################
# Affine
######################################################################

=begin

xd = a1 * x + b1 * y + d1
yd = a2 * x + b2 * y + d2

y = (-a2 * xd + a1 * yd - a1 * d2 + a2 * d1) / (a1 * b2 - a2 * b1)
x = (-b2 * xd + b1 * yd - b1 * d2 + b2 * d1) / (a2 * b1 - a1 * b2)

(a1, a2): x axis vector.
(b1, b2): y axis vector.
(d1, d2): move vector.

=end

class Affine

  def initialize(a1, a2, b1, b2, d1, d2)
    @a1 = a1; @a2 = a2
    @b1 = b1; @b2 = b2
    @d1 = d1; @d2 = d2
    @a1d2a2d1 = -a1 * d2 + a2 * d1
    @b1d2b2d1 = -b1 * d2 + b2 * d1
    @a1b2a2b1 = a1 * b2 - a2 * b1
    @a2b1a1b2 = a2 * b1 - a1 * b2
  end

  def xd(x, y)
    return @a1 * x + @b1 * y + @d1
  end

  def yd(x, y)
    return @a2 * x + @b2 * y + @d2
  end

  def x(xd, yd)
    return (-@b2 * xd + @b1 * yd + @b1d2b2d1) / @a2b1a1b2
  end

  def y(xd, yd)
    return (-@a2 * xd + @a1 * yd + @a1d2a2d1) / @a1b2a2b1
  end

end

######################################################################
# Image filter.
######################################################################

class ImageFilter
  def effect(src_image, src_x, src_y, width, height, dst_image, dst_x, dst_y)
  end
end

######################################################################
# Color.
######################################################################

class Color

  attr_accessor :red, :green, :blue

  def initialize(red, green, blue)
    @red   = red.to_i
    @green = green.to_i
    @blue  = blue.to_i
  end

  def to_hsb
    return Color.rgb_to_hsb(@red, @green, @blue)
  end

  def Color.hsb_to_rgb(hue, saturation, brightness)
    r = 0; g = 0; b = 0
    if saturation == 0.0
      r = g = b = (brightness * 255.0 + 0.5).to_i
    else
      h = (hue - hue.to_i.to_f) * 6.0
      f = h - h.to_i.to_f
      p = brightness * (1.0 - saturation)
      q = brightness * (1.0 - saturation * f)
      t = brightness * (1.0 - (saturation * (1.0 - f)))
      case h.to_i
      when 0
        r = (brightness * 255.0 + 0.5).to_i
        g = (t * 255.0 + 0.5).to_i
        b = (p * 255.0 + 0.5).to_i
      when 1
        r = (q * 255.0 + 0.5).to_i
        g = (brightness * 255.0 + 0.5).to_i
        b = (p * 255.0 + 0.5).to_i
      when 2
        r = (p * 255.0 + 0.5).to_i
        g = (brightness * 255.0 + 0.5).to_i
        b = (t * 255.0 + 0.5).to_i
      when 3
        r = (p * 255.0 + 0.5).to_i
        g = (q * 255.0 + 0.5).to_i
        b = (brightness * 255.0 + 0.5).to_i
      when 4
        r = (t * 255.0 + 0.5).to_i
        g = (p * 255.0 + 0.5).to_i
        b = (brightness * 255.0 + 0.5).to_i
      when 5
        r = (brightness * 255.0 + 0.5).to_i
        g = (p * 255.0 + 0.5).to_i;
        b = (q * 255.0 + 0.5).to_i;
      end
    end
    return r, g, b
  end

  def Color.rgb_to_hsb(r, g, b)

    hue = saturation = brightness = 0.0

    cmax = (r > g) ? r : g
    cmax = b > cmax ? b : cmax
    cmin = (r < g) ? r : g
    cmin = b < cmin ? b : cmin;

    brightness = cmax.to_f / 255.0;
    if cmax != 0
      saturation = (cmax - cmin).to_f / cmax.to_f
    else
      saturation = 0.0
    end
    if saturation == 0.0
      hue = 0.0
    else
      redc   = (cmax - r).to_f / (cmax - cmin).to_f
      greenc = (cmax - g).to_f / (cmax - cmin).to_f
      bluec  = (cmax - b).to_f / (cmax - cmin).to_f
      if r == cmax
        hue = bluec - greenc
      elsif g == cmax
        hue = 2.0 + redc - bluec
      else
        hue = 4.0 + greenc - redc
      end
      hue = hue / 6.0
      if hue < 0.0
        hue = hue + 1.0
      end
    end

   return hue, saturation, brightness

  end

  BLACK   = Color.new(  0,   0,   0)
  BLUE    = Color.new(  0,   0, 255)
  GREEN   = Color.new(  0, 255,   0)
  CYAN    = Color.new(  0, 255, 255)
  RED     = Color.new(255,   0,   0)
  MAGENTA = Color.new(255,   0, 255)
  YELLOW  = Color.new(255, 255,   0)
  WHITE   = Color.new(255, 255, 255)

end

######################################################################
# PNG utility.
######################################################################

class ImageIO

  def save(image, outp)
  end

  def load(inp)
  end

end

class PNGIO < ImageIO

  SIGNATURE = "\x89PNG\x0d\x0a\x1a\x0a"

  def save_file(image, file)
  end

  def save(image, outp)
    if outp.kind_of?(String)
      begin
        outp = File.new(outp, "w")
      rescue
        raise "Cannot open PNG stream: " + outp.to_s
      end
    end
    outp.binmode
    begin
      # PNG file signature
      outp.write(SIGNATURE)
      # IHDR image header
      #   width, height
      #   color depth, color type,
      #   compress method, filter type, interlace type
      data = ""
      append_int(data, image.width)
      append_int(data, image.height)
      data << 8
      data << (image.enable_alpha ? 6 : 2)
      data << 0 << 0 << 0
      write_chunk(outp, "IHDR", data)
      # IDAT image data
      #   image data
      data = to_idat(image)
      write_chunk(outp, "IDAT", data)
      # IEND end
      write_chunk(outp, "IEND", "")
    rescue
      raise "Cannot write PNG stream: " + outp.to_s
    ensure
      outp.close
    end
  end

  def load(inp)
    if inp.kind_of?(String)
      begin
        inp = File.new(inp, "r")
      rescue
        raise "Cannot open PNG file: " + inp.to_s
      end
    end
    inp.binmode
    begin
      # PNG file signature.
      signature = inp.read(8)
      if signature != SIGNATURE then
        raise "Illegal PNG format: " + inp.to_s
      end
      # Read PNG chunks.
      idat = ""
      width = -1
      height = -1
      while !inp.eof
        type, data = read_chunk(inp)
        if type == "IHDR" then
          # IHDR: Read header.
          width      = to_int(data, 0)
          height     = to_int(data, 4)
          depth      = data[8].to_i
          color_type = data[9].to_i
          compress   = data[10].to_i
          filter     = data[11].to_i
          interlace  = data[12].to_i
          # Check support PNG format.
          if depth != 8 then
            raise "Not support color depth: " + depth
          end
          if color_type != 2 && color_type != 6 then
            raise "Not support color type: " + color_type
          end
          if compress != 0 then
            raise "Not support compress method: " + compress
          end
          if filter != 0 then
            raise "Not support filter method: " + filter
          end
          if interlace != 0 then
            raise "Not support filter method: " + interlace
          end
        elsif type == "IDAT" then
          # IDAT: Read pixel data.
          idat << data
        elsif type == "IEND" then
          # IEND: PNG data end.
          break
        end
      end
      idat = Zlib::Inflate.inflate(idat)
      if idat.length == 0 || width < 0 || height < 0 then
        raise "Illegal format: " + inp.to_s
      end
      # Create image.
      if color_type == 2 then
        # RGB, 8bit, disable alpha
        image = Image.new(width, height, 0xffffff, false)
        dat_index = 0; pix_index = 0
        pixels = image.pixels
        for y in 0..(height - 1)
          dat_index += 1
          for x in 0..(width - 1)
            r = idat[dat_index    ].to_i
            g = idat[dat_index + 1].to_i
            b = idat[dat_index + 2].to_i
            dat_index += 3
            pixels[pix_index] = [r, g, b, 255]
            pix_index += 1
          end
        end
      elsif color_type == 6 then
        # RGB, 8bit, enable alpha
        image = Image.new(width, height, 0xffffff, true)
        dat_index = 0; pix_index = 0
        pixels = image.pixels
        for y in 0..(height - 1)
          dat_index += 1
          for x in 0..(width - 1)
            r = idat[dat_index    ].to_i
            g = idat[dat_index + 1].to_i
            b = idat[dat_index + 2].to_i
            a = idat[dat_index + 3].to_i
            dat_index += 4
            pixels[pix_index] = [r, g, b, a]
            pix_index += 1
          end
        end
      end
    rescue
      raise "Cannot read PNG stream: " + inp.to_s
    ensure
      inp.close
    end
    return image
  end

  def to_idat(image)
    data = ""
    ymax = image.height - 1
    xmax = image.width - 1
    i = 0
    pix = image.pixels
    if !image.enable_alpha then
      for y in 0..ymax
        data << "\x00"
        for x in 0..xmax
          c = pix[i]
          data << c[0] << c[1] << c[2]
          i += 1
        end
      end
    else
      for y in 0..ymax
        data << "\x00"
        for x in 0..xmax
          c = pix[i]
          data << c[0] << c[1] << c[2] << c[3]
          i += 1
        end
      end
    end
    return Zlib::Deflate.deflate(data)
  end
  private :to_idat

  def append_int(str, c)
    str << ((c >> 24) & 0xff)
    str << ((c >> 16) & 0xff)
    str << ((c >> 8) & 0xff)
    str << (c & 0xff)
  end
  private :append_int

  def write_chunk(outp, type, data)
    # Data length, Cunk type, Chunk data, CRC32
    write_int(outp, data.length)
    outp.write(type)
    outp.write(data)
    crc32 = Zlib.crc32(type)
    write_int(outp, Zlib.crc32(data, crc32))
  end
  private :write_chunk

  def write_int(outp, value)
    outp.putc((value >> 24) & 0xff)
    outp.putc((value >> 16) & 0xff)
    outp.putc((value >> 8) & 0xff)
    outp.putc(value & 0xff)
  end
  private :write_int

  def to_int(str, offset)
    value = str[offset].to_i
    value = (value << 8) | (str[offset + 1].to_i & 0xff)
    value = (value << 8) | (str[offset + 2].to_i & 0xff)
    value = (value << 8) | (str[offset + 3].to_i & 0xff)
    return value
  end
  private :to_int

  def read_chunk(inp)
    # Data length, Cunk type, Chunk data, CRC32
    length = read_int(inp)
    type = inp.read(4);
    data = inp.read(length)
    crc32 = read_int(inp)
    crc32_check = Zlib.crc32(type)
    crc32_check = Zlib.crc32(data, crc32_check)
    if crc32 != crc32_check then
      raise "PNG format error(CRC32): type: " + type
    end
    return type, data
  end
  private :read_chunk

  def read_int(inp)
    value = inp.getc() & 0xff
    value = (value << 8) | (inp.getc() & 0xff)
    value = (value << 8) | (inp.getc() & 0xff)
    value = (value << 8) | (inp.getc() & 0xff)
    return value
  end
  private :read_int

end

end
