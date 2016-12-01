require 'chess/move_predicate'

module Chess
  class Piece
    extend MovePredicate

    attr_reader :team
    def initialize(team)
      @team = team
    end

    def accessible_fields(state)
      context = MoveContext.new(state, state.board.where(self))
      self.class::MOVES.map do |directive|
        directive.apply(context)
      end.flatten.select do |target|
        target.empty? || self.team != target.piece.team
      end.uniq
    end
  end

  class Bishop < Piece
    MOVES = [
      RELATIVE(1, 1).indefinitely.all_directions
    ]
  end

  class Knight < Piece
    MOVES = [
      RELATIVE(2, 1).or(1, 2).all_directions,
    ]
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

    def ==(other)
      other.is_a?(King) && other.team == self.team
    end
  end

  class Pawn < Piece
    MOVES = [
      FORWARD(1).non_capturing,
      FORWARD(2).non_capturing.if_outset,
      RELATIVE(1, 1).or(1, -1).capture_only.en_passant,
    ]
  end
end
