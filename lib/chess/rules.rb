module Chess
  module Rules
    extend self
    def check?(state, team = state.to_move)
      Utils.field_attacked?(state.board.king_square(team), on: state.board, by: team.opponent)
    end

    def legal_move?(state, move)
      !check?(state.execute(move), state.to_move)
    end

    def king_square(board, team)
      board.where(King.new(team))
    end
  end
end
