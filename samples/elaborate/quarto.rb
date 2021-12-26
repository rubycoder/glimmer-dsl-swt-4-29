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

require 'glimmer-dsl-swt'

class Quarto
  include Glimmer::UI::CustomShell
  
  BOARD_DIAMETER = 430
  CELL_DIAMETER = 68
  CELL_LINE_WIDTH = 5
  CELL_MARGIN = 5
  ROW_COUNT = 4
  COLUMN_COUNT = 4
  
  body {
    shell {
      text 'Glimmer Quarto'
      minimum_size BOARD_DIAMETER, BOARD_DIAMETER + 24
      maximum_size BOARD_DIAMETER, BOARD_DIAMETER + 24
      
      rectangle(0, 0, BOARD_DIAMETER, BOARD_DIAMETER) {
        background :black
        
        oval(0, 0, :max, :max) { # takes max dimensions by default
          foreground rgb(239, 196, 156)
          line_width CELL_LINE_WIDTH
          
          x_offset = (BOARD_DIAMETER - COLUMN_COUNT * (CELL_DIAMETER + CELL_LINE_WIDTH + CELL_MARGIN) + CELL_LINE_WIDTH + CELL_MARGIN) / 2.0
          y_offset = (BOARD_DIAMETER - ROW_COUNT * (CELL_DIAMETER + CELL_LINE_WIDTH + CELL_MARGIN) + CELL_LINE_WIDTH + CELL_MARGIN) / 2.0
          ROW_COUNT.times do |row|
            COLUMN_COUNT.times do |column|
              oval(x_offset + column * (CELL_DIAMETER + CELL_LINE_WIDTH + CELL_MARGIN), y_offset + row * (CELL_DIAMETER + CELL_LINE_WIDTH + CELL_MARGIN), CELL_DIAMETER, CELL_DIAMETER) {
                foreground rgb(239, 196, 156)
                line_width CELL_LINE_WIDTH
              }
            end
          end
          
#           7.times do |row|
#             columns = row <= 3 ? row + 1 : (7 - row)
#             columns.times do |column|
#               oval((BOARD_WIDTH/2.0 - CELL_DIAMETER/2.0) * column, CELL_LINE_WIDTH + CELL_DIAMETER * row, CELL_DIAMETER, CELL_DIAMETER) {
#                 foreground rgb(239, 196, 156)
#                 line_width 5
#               }
#             end
#           end
        }
      }
    }
  }
end

Quarto.launch
