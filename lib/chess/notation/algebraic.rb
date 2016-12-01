require 'chess/field'
require 'chess/piece'

module Chess
  module Notation
    module Algebraic
      module Utils
        def parse_field(input)
          to_coordinates(*input.split(''))
        end

        def to_coordinates(file, rank)
          [8 - rank.to_i, file.bytes.first - 97]
        end
      end
      extend Utils

      module Field
        def algebraic
          [(self.file + 97).chr, 8 - self.rank].join
        end
        alias_method :to_s, :algebraic

        def inspect
          [self, '(', self.piece || '_', ')'].join
        end

        def self.included(base)
          ('a'..'h').each do |file|
            (1..8).each do |rank|
              notation = [file, rank].join
              base.define_singleton_method notation do
                self.new(*Algebraic.to_coordinates(file, rank))
              end
            end
          end
        end
      end

      module Board
        def at(any)
          case any
          when String
            self[*Algebraic.parse_field(any)]
          when Chess::Field
            self[*any.coordinates]
          end
        end
      end

      module Piece
        def algebraic
          self.class.name.split("::").last[0]
        end
      end

      module Knight
        def algebraic
          'N'
        end
      end
      Chess::Field.include(Algebraic::Field)
      Chess::Board.include(Algebraic::Board)
      Chess::Piece.include(Algebraic::Piece)
      Chess::Knight.include(Algebraic::Knight)
    end
  end
end
