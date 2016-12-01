module Chess
  class MoveContext < Struct.new(:state, :from)
    def board
      @board ||= state.board
    end

    def piece
      @piece ||= from.piece
    end
  end
end
