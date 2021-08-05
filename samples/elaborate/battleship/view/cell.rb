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

class Battleship
  module View
    class Cell
      include Glimmer::UI::CustomWidget
      
      class << self
        attr_accessor :dragging
        alias dragging? dragging
      end
      
      COLOR_WATER = rgb(156, 211, 219)
      COLOR_SHIP = :gray
      COLOR_PLACED = :white
      
      options :game, :player, :row_index, :column_index, :ship
      option :type, default: :grid # other type is :ship
      
      body {
        canvas {
          if type == :grid
            background <= [model, :ship, on_read: ->(s) {s ? COLOR_SHIP : COLOR_WATER}]
          else
            background <= [ship, :top_left_cell, on_read: ->(c) {c ? COLOR_PLACED : COLOR_SHIP} ]
          end
          
          rectangle(0, 0, [:max, -1], [:max, -1])
          oval(:default, :default, 10, 10)
          oval(:default, :default, 5, 5) {
            background :black
          }
          
          if player == :you
            on_drag_detected do |event|
              Cell.dragging = true
              body_root.cursor = :hand if type == :grid
            end
          
            on_drag_set_data do |event|
              the_ship = ship || model&.ship
              if the_ship
                event.data = the_ship.name.to_s
              else
                event.doit = false
                Cell.dragging = false
              end
            end
            
            on_mouse_up do
              Cell.dragging = false
              change_cursor
            end
            
            if type == :grid
              on_mouse_move do |event|
                change_cursor
              end
              
              on_mouse_hover do |event|
                change_cursor
              end
              
              on_mouse_up do |event|
                begin
                  model.ship&.toggle_orientation!
                rescue => e
                  Glimmer::Config.logger.debug e.full_message
                end
                change_cursor
              end
              
              on_drop do |event|
                ship_name = event.data
                place_ship(ship_name.to_s.to_sym) if ship_name
                Cell.dragging = false
                change_cursor
              end
            end
          end
        }
      }
      
      def model
        game.grids[player].cell_rows[row_index][column_index] if type == :grid
      end
      
      def place_ship(ship_name)
        ship = game.ship_collections[player].ships[ship_name]
        begin
          old_ship_top_left_cell = ship.top_left_cell
          ship.top_left_cell = model
          if old_ship_top_left_cell
            ship.length.times do |index|
              if ship.orientation == :horizontal
                old_cell = game.grids[player].cell_rows[old_ship_top_left_cell.row_index][old_ship_top_left_cell.column_index + index]
              else
                old_cell = game.grids[player].cell_rows[old_ship_top_left_cell.row_index + index][old_ship_top_left_cell.column_index]
              end
              old_cell.reset!
            end
          end
          ship.length.times do |index|
            cell = game.grids[player].cell_rows[row_index][column_index + index]
            cell.ship = ship
            cell.ship_index = index
          end
        rescue => e
          Glimmer::Config.logger.debug(e.full_message)
        end
      end
      
      def change_cursor
        if type == :grid && model.ship && !Cell.dragging?
          body_root.cursor = model.ship.orientation == :horizontal ? :sizens : :sizewe
        elsif !Cell.dragging?
          body_root.cursor = :arrow
        end
      end
    end
  end
end
