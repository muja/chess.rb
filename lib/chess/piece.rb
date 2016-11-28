require 'chess/move_predicate'

module Chess
  class Piece
    extend MovePredicate

    attr_reader :team
    def initialize(team)
      @team = team
    end

    def possible_moves(context)
      context.piece = self
      self.class::MOVES.map do |move|
        move.apply(context)
      end.flatten.select do |move|
        move.to.empty? || context.piece.team != move.to.piece.team
      end.uniq
    end

    # algebraic notation
    def an
      self.class.name[0]
    end
  end

  class Bishop < Piece
    MOVES = [
      RELATIVE(1, 1).indefinitely.all_directions
    ]
  end

  class Knight < Piece
    MOVES = [
      RELATIVE(2, 1).all_directions,
      RELATIVE(1, 2).all_directions
    ]

    def an
      'N'
    end
  end

  class Rook < Piece
    MOVES = [
      FORWARD(1).indefinitely.all_directions
    ]
  end

  class Queen < Piece
    MOVES = Rook::MOVES + Bishop::MOVES
  end

  class King < Piece
    MOVES = Queen::MOVES.map(&:once).push(CASTLE())
  end

  class Pawn < Piece
    MOVES = [
      # NON-CAPTURING
      FORWARD(1).if { |move| move.to.empty? },
      FORWARD(2).if { |move| move.to.empty? && (move.to.rank - move.piece.team.home_rank).abs == 3 },

      # CAPTURING
      RELATIVE(1, 1).if { |move| move.to.has_piece? && move.to.piece.team != move.piece.team },
      RELATIVE(1, -1).if { |move| move.to.has_piece? && move.to.piece.team != move.piece.team },
      EN_PASSANT()
    ]
  end
end
