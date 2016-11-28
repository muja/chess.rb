require 'chess/notation/algebraic'
require 'chess/board'
require 'chess/castle_rights'
require 'chess/state'
require 'chess/piece'

module Chess
  module Notation
    module FEN
      module Board
        def fen
          self.fields.map do |rank|
            "".tap do |line|
              empty_spaces = 0
              rank.each do |field|
                if field.has_piece?
                  line << empty_spaces.to_s if empty_spaces > 0
                  empty_spaces = 0
                  line << field.piece.fen
                else
                  empty_spaces += 1
                end
              end
              line << empty_spaces.to_s if empty_spaces > 0
            end
          end.join('/')
        end
      end

      module State
        def fen
          [
            self.board.fen,
            self.to_move.white? ? 'w' : 'b',
            [self.castle_rights.fen, '-'].max,
            "-",
            0,
            0
          ].join " "
        end
      end

      module CastleRights
        def fen
          "".tap do |fen|
            castle_rights.each do |team, sides|
              sides.each do |side|
                s = case side
                when CastleRights::Queenside then 'q'
                when CastleRights::Kingside then 'k'
                end
                s.upcase! if team.white?
                fen << s
              end
            end
          end
        end
      end

      module Piece
        def fen
          self.team == Team::BLACK ? self.algebraic.downcase : self.algebraic.upcase;
        end

        alias_method :to_s, :fen
      end
      Chess::Board.include(FEN::Board)
      Chess::State.include(FEN::State)
      Chess::CastleRights.include(FEN::CastleRights)
      Chess::Piece.include(FEN::Piece)
    end
  end
end
