# frozen_string_literal: true

# This class creates a SVG files.
# Code from: https://github.com/samvincent/rqrcode-rails3
module RQRCode
  module Export
    module SVG
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

      #
      # Render the SVG from the Qrcode.
      #
      # Options:
      # offset - Padding around the QR Code (e.g. 10)
      # fill - Background color (e.g "ffffff" or :white)
      # color - Foreground color for the code (e.g. "000000" or :black)
      # module_size - The Pixel size of each module (e.g. 11)
      # shape_rendering - Defaults to crispEdges
      # standalone - wether to make this a full SVG file, or only svg to embed
      #              in other svg.
      #
      def as_svg(options = {})
        offset = options[:offset].to_i || 0
        color = options[:color] || "000"
        shape_rendering = options[:shape_rendering] || "crispEdges"
        module_size = options[:module_size] || 11
        standalone = options[:standalone].nil? ? true : options[:standalone]

        # height and width dependent on offset and QR complexity
        dimension = (@qrcode.module_count * module_size) + (2 * offset)

        xml_tag = %(<?xml version="1.0" standalone="yes"?>)
        open_tag = %(<svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:ev="http://www.w3.org/2001/xml-events" width="#{dimension}" height="#{dimension}" shape-rendering="#{shape_rendering}">)
        close_tag = "</svg>"

        result = []
        modules_array = @qrcode.modules

        matrix_height = modules_array.length + 1
        matrix_width = modules_array.first.length + 1
        edge_matrix = Array.new(matrix_height) { Array.new(matrix_width){ Array.new } }

        false_row = [[false] * modules_array.first.length ]

        (false_row + modules_array + false_row).each_cons(2).with_index do |row_pair, row_index|
          first_row, second_row = row_pair
          # horizontal edges
          first_row.zip(second_row).each.with_index do |cell_pair, column_index|
            edge = case cell_pair
            when [true, false] then Edge.new column_index + 1, row_index, :left
            when [false, true] then Edge.new column_index, row_index, :right
            end
            edge_matrix[edge.start_y][edge.start_x] << edge  if edge
          end
          #  vertical edges
          ([false] + second_row + [false]).each_cons(2).each.with_index do |cell_pair, column_index|
            edge = case cell_pair
            when [true, false] then Edge.new column_index, row_index, :down
            when [false, true] then Edge.new column_index, row_index + 1, :up
            end
            edge_matrix[edge.start_y][edge.start_x] << edge  if edge
          end
        end

        # clean up empty cells
        edge_matrix.each_with_index do |matrix_row, row_index|
          matrix_row.each_with_index do |cell, column_index|
            matrix_row[column_index] = nil if cell.empty?
          end
        end

        edge_count = edge_matrix.flatten.compact.count

        path = []
        while edge_count > 0
          edge_loop = []
          matrix_cell = edge_matrix.find{|row| row.any?}.find{|cell| ! cell.nil? && ! cell.empty?}
          edge = matrix_cell.first
          while edge
            edge_loop << edge
            matrix_cell = edge_matrix[edge.start_y][edge.start_x]
            matrix_cell.delete edge
            edge_matrix[edge.start_y][edge.start_x] = nil  if matrix_cell.empty?
            edge_count -= 1
            # try to find an edge continuing the current edge
            matrix_cell = edge_matrix[edge.end_y][edge.end_x]
            edge = matrix_cell.nil? ? nil : matrix_cell.first
          end

          first_edge = edge_loop.first
          edge_loop_string = "M#{first_edge.start_x} #{first_edge.start_y}"

          edge_loop.chunk(&:direction).to_a[0...-1].each do |direction, edges|
            direction_string = case direction
            when :up then "v-"
            when :down then "v"
            when :left then "h-"
            when :right then "h"
            end
            edge_loop_string += "#{direction_string}#{edges.length}"
          end
          edge_loop_string += "z"

          path << edge_loop_string
        end

        result << %{<path d="#{path.join("")}" style="fill:##{color}" transform="translate(#{offset},#{offset}) scale(#{module_size})"/>}

        if options[:fill]
          result.unshift %(<rect width="#{dimension}" height="#{dimension}" x="0" y="0" style="fill:##{options[:fill]}"/>)
        end

        if standalone
          result.unshift(xml_tag, open_tag)
          result << close_tag
        end

        result.join("\n")
      end
    end
  end
end

RQRCode::QRCode.send :include, RQRCode::Export::SVG
