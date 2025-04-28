# frozen_string_literal: true

# This class creates a SVG files.
# Initial code from: https://github.com/samvincent/rqrcode-rails3
module RQRCode
  module Export
    module SVG
      class BaseOutputSVG
        attr_reader :result

        def initialize(qrcode)
          @qrcode = qrcode
          @result = []
        end
      end

      class Path < BaseOutputSVG
        def build(module_size, options = {})
          # Extract values from options
          color = options[:color]
          offset_x = options[:offset_x].to_i
          offset_y = options[:offset_y].to_i

          # Prefix hexadecimal colors unless using a named color (symbol)
          color = "##{color}" unless color.is_a?(Symbol)

          modules_array = @qrcode.modules
          matrix_width = matrix_height = modules_array.length + 1
          empty_row = [Array.new(matrix_width - 1, false)]
          edge_matrix = Array.new(matrix_height) { Array.new(matrix_width) }

          (empty_row + modules_array + empty_row).each_cons(2).with_index do |row_pair, row_index|
            first_row, second_row = row_pair

            # horizontal edges
            first_row.zip(second_row).each_with_index do |cell_pair, column_index|
              edge = case cell_pair
              when [true, false] then Edge.new column_index + 1, row_index, :left
              when [false, true] then Edge.new column_index, row_index, :right
              end

              (edge_matrix[edge.start_y][edge.start_x] ||= []) << edge if edge
            end

            # vertical edges
            ([false] + second_row + [false]).each_cons(2).each_with_index do |cell_pair, column_index|
              edge = case cell_pair
              when [true, false] then Edge.new column_index, row_index, :down
              when [false, true] then Edge.new column_index, row_index + 1, :up
              end

              (edge_matrix[edge.start_y][edge.start_x] ||= []) << edge if edge
            end
          end

          edge_count = edge_matrix.flatten.compact.count
          path = []

          while edge_count > 0
            edge_loop = []
            next_matrix_cell = edge_matrix.find(&:any?).find { |cell| cell&.any? }
            edge = next_matrix_cell.first

            while edge
              edge_loop << edge
              matrix_cell = edge_matrix[edge.start_y][edge.start_x]
              matrix_cell.delete edge
              edge_matrix[edge.start_y][edge.start_x] = nil if matrix_cell.empty?
              edge_count -= 1

              # try to find an edge continuing the current edge
              edge = edge_matrix[edge.end_y][edge.end_x]&.first
            end

            first_edge = edge_loop.first
            edge_loop_string = SVG_PATH_COMMANDS[:move]
            edge_loop_string += "#{first_edge.start_x} #{first_edge.start_y}"

            edge_loop.chunk(&:direction).to_a[0...-1].each do |direction, edges|
              edge_loop_string << "#{SVG_PATH_COMMANDS[direction]}#{edges.length}"
            end
            edge_loop_string << SVG_PATH_COMMANDS[:close]

            path << edge_loop_string
          end

          @result << %{<path d="#{path.join}" fill="#{color}" transform="translate(#{offset_x},#{offset_y}) scale(#{module_size})"/>}
        end
      end

      class Rect < BaseOutputSVG
        def build(module_size, options = {})
          # Extract values from options
          color = options[:color]
          offset_x = options[:offset_x].to_i
          offset_y = options[:offset_y].to_i

          # Prefix hexadecimal colors unless using a named color (symbol)
          color = "##{color}" unless color.is_a?(Symbol)

          @qrcode.modules.each_index do |c|
            tmp = []
            @qrcode.modules.each_index do |r|
              x = r * module_size + offset_x
              y = c * module_size + offset_y

              next unless @qrcode.checked?(c, r)
              tmp << %(<rect width="#{module_size}" height="#{module_size}" x="#{x}" y="#{y}" fill="#{color}"/>)
            end

            @result << tmp.join
          end
        end
      end

      class Edge < Struct.new(:start_x, :start_y, :direction)
        def end_x
          case direction
          when :right then start_x + 1
          when :left then start_x - 1
          else start_x
          end
        end

        def end_y
          case direction
          when :down then start_y + 1
          when :up then start_y - 1
          else start_y
          end
        end
      end

      DEFAULT_SVG_ATTRIBUTES = [
        %(version="1.1"),
        %(xmlns="http://www.w3.org/2000/svg"),
        %(xmlns:xlink="http://www.w3.org/1999/xlink"),
        %(xmlns:ev="http://www.w3.org/2001/xml-events")
      ]

      SVG_PATH_COMMANDS = {
        move: "M",
        up: "v-",
        down: "v",
        left: "h-",
        right: "h",
        close: "z"
      }

      #
      # Render the SVG from the Qrcode.
      #
      # Options:
      # offset          - Padding around the QR Code in pixels
      #                   (default 0)
      # offset_x        - X Padding around the QR Code in pixels
      #                   (default offset)
      # offset_y        - Y Padding around the QR Code in pixels
      #                   (default offset)
      # fill            - Background color e.g "ffffff"
      #                   (default none)
      # color           - Foreground color e.g "000"
      #                   (default "000")
      # module_size     - The Pixel size of each module
      #                   (defaults 11)
      # shape_rendering - SVG Attribute: auto | optimizeSpeed | crispEdges | geometricPrecision
      #                   (defaults crispEdges)
      # standalone      - Whether to make this a full SVG file, or only an svg to embed in other svg
      #                   (default true)
      # use_path        - Use <path> to render SVG rather than <rect> to significantly reduce size
      #                   and quality. This will become the default in future versions.
      #                   (default false)
      # viewbox         - replace `width` and `height` in <svg> with a viewBox, allows CSS scaling
      #                   (default false)
      # svg_attributes  - A optional hash of custom <svg> attributes. Existing attributes will remain.
      #                   (default {})
      #
      def as_svg(options = {})
        fill = options[:fill]
        use_path = options[:use_path]
        offset = options[:offset].to_i
        offset_x = options.key?(:offset_x) ? options[:offset_x].to_i : offset
        offset_y = options.key?(:offset_y) ? options[:offset_y].to_i : offset
        color = options[:color] || "000"
        shape_rendering = options[:shape_rendering] || "crispEdges"
        module_size = options[:module_size] || 11
        standalone = options[:standalone].nil? ? true : options[:standalone]
        viewbox = options[:viewbox].nil? ? false : options[:viewbox]
        svg_attributes = options[:svg_attributes] || {}

        # height and width dependent on offset and QR complexity
        width = (@qrcode.module_count * module_size) + (2 * offset_x)
        height = (@qrcode.module_count * module_size) + (2 * offset_y)
        dimension = [width, height].max
        # use dimensions differently if we are using a viewBox
        dimensions_attr = viewbox ? %(viewBox="0 0 #{width} #{height}") : %(width="#{width}" height="#{height}")

        svg_tag_attributes = (DEFAULT_SVG_ATTRIBUTES + [
          dimensions_attr,
          %(shape-rendering="#{shape_rendering}")
        ] + svg_attributes.map { |k, v| %(#{k}="#{v}") }).join(" ")

        xml_tag = %(<?xml version="1.0" standalone="yes"?>)
        open_tag = %(<svg #{svg_tag_attributes}>)
        close_tag = "</svg>"

        output_tag = (use_path ? Path : Rect).new(@qrcode)
        output_tag.build(module_size, offset_x: offset_x, offset_y: offset_y, color: color)

        if fill
          # Prefix hexadecimal colors unless using a named color (symbol)
          fill = "##{fill}" unless fill.is_a?(Symbol)
          output_tag.result.unshift %(<rect width="#{dimension}" height="#{dimension}" x="0" y="0" fill="#{fill}"/>)
        end

        if standalone
          output_tag.result.unshift(xml_tag, open_tag)
          output_tag.result << close_tag
        end

        output_tag.result.join
      end
    end
  end
end

RQRCode::QRCode.send :include, RQRCode::Export::SVG
