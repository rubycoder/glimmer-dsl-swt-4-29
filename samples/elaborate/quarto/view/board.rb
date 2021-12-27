# Copyright (c) 2007-2021 Andy Maleh
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require_relative 'cell'

class Quarto
  module View
    class Board
      include Glimmer::UI::CustomShape
      
      body {
        rectangle(0, 0, BOARD_DIAMETER, BOARD_DIAMETER) {
          background :black
          
          text('Glimmer Quarto', BOARD_DIAMETER - 109, BOARD_DIAMETER - 23) {
            foreground rgb(239, 196, 156)
            font height: 14, style: :bold
          }
          
          oval(0, 0, :max, :max) {
            foreground rgb(239, 196, 156)
            line_width CELL_LINE_WIDTH
            
            board_x_offset = (BOARD_DIAMETER - COLUMN_COUNT * (CELL_DIAMETER + CELL_LINE_WIDTH + CELL_MARGIN) + CELL_LINE_WIDTH + CELL_MARGIN) / 2.0
            board_y_offset = (BOARD_DIAMETER - ROW_COUNT * (CELL_DIAMETER + CELL_LINE_WIDTH + CELL_MARGIN) + CELL_LINE_WIDTH + CELL_MARGIN) / 2.0
            
            ROW_COUNT.times do |row|
              COLUMN_COUNT.times do |column|
                cell(row: row, column: column)
              end
            end
          }
        }
      }
      
      def board_rotation_transform
        @board_rotation_transform ||= transform {
          translate BOARD_DIAMETER/2.0, BOARD_DIAMETER/2.0
          rotate 45
          translate -BOARD_DIAMETER/2.0, -BOARD_DIAMETER/2.0
        }
      end
    end
  end
end
