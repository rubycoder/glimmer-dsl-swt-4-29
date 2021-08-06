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

require_relative 'grid'
require_relative 'ship'

class Battleship
  module Model
    class Game
      BATTLESHIPS = {
        aircraft_carrier: 5,
        battleship: 4,
        submarine: 3,
        cruiser: 3,
        destroyer: 2
      }
      PLAYERS = [:enemy, :you]
      
      attr_reader :grids, :ship_collections
      attr_accessor :started, :current_player
      alias started? started
            
      def initialize
        @grids = PLAYERS.reduce({}) { |hash, player| hash.merge(player => Grid.new(self, player)) }
        @ship_collections = PLAYERS.reduce({}) { |hash, player| hash.merge(player => ShipCollection.new(self, player)) }
        @started = false
        @current_player = :enemy
      end
      
      def battle!
        self.started = true
        place_enemy_ships!
        enemy_attack!
      end
      
      def reset!
        self.started = false
        self.current_player = :enemy
        @grids.values.each(&:reset!)
        @ship_collections.values.each(&:reset!)
      end
      
      def attack!(row_index, column_index)
        return unless started?
        cell = opposite_grid.cell_rows[row_index][column_index]
        cell.hit = !!cell.ship
        switch_player!
        enemy_attack! if current_player == :enemy
      end
      
      # Enemy attack artificial intelligence
      def enemy_attack!
        # TODO if last move was a hit, target a neighbor unless its ship is sunk
        cell = nil
        begin
          if @last_enemy_attack_row_index
            last_cell = opposite_grid.cell_rows[@last_enemy_attack_row_index][@last_enemy_attack_column_index]
            # TODO if last cell ship is sunk, pursue a random point instead
            if last_cell.hit?
              # TODO check last last cell to identify orientation for next move if possible
              orientation = Ship::ORIENTATIONS[(rand * 2).to_i]
              offset = 1 * ((rand * 2).to_i == 1 ? 1 : -1)
              if orientation == :horizontal
#                 if @last_enemy_attack_column_index + offset
                # TODO check if offset hits boundary. If so, multiply offset by -1
                cell = opposite_grid.cell_rows[@last_enemy_attack_row_index][@last_enemy_attack_column_index]
              else
              end
            else
              # TODO check last last cell when there is no hit to attempt a hit in another direction
              # Consider keeping last last last cell too (or just keeping history in general)
            end
          end
          random_row_index = (rand * Grid::HEIGHT).to_i
          random_column_index = (rand * Grid::WIDTH).to_i
          cell = opposite_grid.cell_rows[random_row_index][random_column_index]
        end until cell.hit.nil?
        attack!(random_row_index, random_column_index)
        @last_last_enemy_attack_row_index = @last_enemy_attack_row_index
        @last_last_enemy_attack_column_index = @last_enemy_attack_column_index
        @last_enemy_attack_row_index = random_row_index
        @last_enemy_attack_column_index = random_column_index
      end
      
      def opposite_grid
        grids[opposite_player]
      end
      
      def opposite_player
        PLAYERS[(PLAYERS.index(current_player) + 1) % PLAYERS.size]
      end
      
      def switch_player!
        self.current_player = opposite_player
      end
      
      private
      
      def place_enemy_ships!
        ship_collection = @ship_collections[:enemy]
        ship_collection.ships.values.each do |ship|
          until ship.top_left_cell
            random_row_index = (rand * Grid::HEIGHT).to_i
            random_column_index = (rand * Grid::WIDTH).to_i
            enemy_grid = @grids[:enemy]
            top_left_cell = enemy_grid.cell_rows[random_row_index][random_column_index]
            top_left_cell.place_ship!(ship)
            begin
              ship.toggle_orientation! if (rand * 2).to_i == 1
            rescue => e
              Glimmer::Config.logger.debug(e.full_message)
            end
          end
        end
      end
    end
  end
end
