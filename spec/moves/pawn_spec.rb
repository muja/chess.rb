module Chess
  RSpec.describe Pawn, "#accessible_fields" do
    context "on the default board" do
      it "can go forward 1 step" do
        state = State.new(Board.default)
        expect(state.board.at('e2').piece.accessible_fields(state)).to include(Field.e3)
      end

      it "can go forward 2 steps" do
        state = State.new(Board.default)
        expect(state.board.at('e2').piece.accessible_fields(state)).to include(Field.e4)
      end

      it "can't go forward 3 steps" do
        state = State.new(Board.default)
        expect(state.board.at('e2').piece.accessible_fields(state)).to_not include(Field.e5)
      end
    end

    context "on the default starting position"

    context "if a pawn just double-stepped next to it" do
      it "can capture it en passant" do
        board = Board.from_map <<-EOF
          ........
          .....p..
          ........
          ....P...
          ........
          ........
          ........
          ........
        EOF
        state = State.new(board).execute(Field.f7.to(Field.f5))
        moves = state.board.at('e5').piece.accessible_fields(state)
        expect(moves).to include(Field.f6)
      end
    end
  end
end
