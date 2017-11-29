require 'chess/notation/algebraic'
require 'chess/board'
require 'chess/castle_rights'
require 'chess/state'
require 'chess/piece'

module Chess
  module Notation
    module FEN
      PIECES = {
        'r' => Rook,
        'n' => Knight,
        'b' => Bishop,
        'q' => Queen,
        'k' => King,
        'p' => Pawn
      }

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
        alias_method :to_s, :fen

        def self.included(base)
          def base.default
            @@default ||= self.from_fen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR")
          end

          def base.from_fen(fen)
            self.new.tap do |board|
              fen.split("/").each_with_index do |line, rank|
                file = 0
                line.chars.each do |char|
                  if piecec = PIECES[char.downcase]
                    board[rank, file].put piecec.new(
                      char.downcase == char ? Team::BLACK : Team::WHITE
                    )
                    file += 1
                  else
                    file += char.to_i
                  end
                end
              end
            end
          end
        end
      end

      module State
        def fen
          [
            self.board.fen,
            self.to_move.white? ? 'w' : 'b',
            [self.castle_rights_fen, '-'].max,
            self.en_passant || '-',
            0,
            0
          ].join " "
        end
      end

      module CastleRights
        def castle_rights_fen
          "".tap do |fen|
            castle_rights.each do |team, sides|
              sides.each do |side|
                s = case side
                when Chess::CastleRights::Queenside then 'q'
                when Chess::CastleRights::Kingside then 'k'
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
      Chess::State.include(FEN::CastleRights)
      Chess::Piece.include(FEN::Piece)
    end
  end
end
