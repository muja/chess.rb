require 'chess/notation/fen'

module Chess
  module Notation
    module Map
      def to_map
        fields.map do |rank|
          rank.map do |field|
            field.has_piece? ? field.piece.fen : '.'
          end.join
        end.join("\n")
      end

      def self.included(base)
        def base.from_map(text)
          Board.new.tap do |board|
            text.lines.each_with_index do |line, rank|
              line.strip.chars.each_with_index do |char, file|
                next if char == '.'
                team = char.downcase == char ? Team::BLACK : Team::WHITE
                piece = {
                  r: Rook,
                  n: Knight,
                  b: Bishop,
                  q: Queen,
                  k: King,
                  p: Pawn
                }[char.downcase.intern].new(team)
                board[rank, file].put(piece)
              end
            end
          end
        end
      end
    end
    Chess::Board.include(Notation::Map)
  end
end
