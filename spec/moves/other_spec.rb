module Chess
  RSpec.describe Piece, "#accessible_fields" do
    context "on the default board" do
      it "only the Knight can move" do
        board = Board.default
        state = State.new(board)
        expect(board.at('a1').piece.accessible_fields(state)).to be_empty
        expect(board.at('b1').piece.accessible_fields(state)).to_not be_empty
        expect(board.at('c1').piece.accessible_fields(state)).to be_empty
        expect(board.at('d1').piece.accessible_fields(state)).to be_empty
        expect(board.at('e1').piece.accessible_fields(state)).to be_empty
        expect(board.at('f1').piece.accessible_fields(state)).to be_empty
        expect(board.at('g1').piece.accessible_fields(state)).to_not be_empty
        expect(board.at('h1').piece.accessible_fields(state)).to be_empty
      end
    end

    context "castling" do
      it "is possible if the King and Rook have not moved" do
        state = State.default.execute(Field.f1.to(Field.h3)).execute(Field.g1.to(Field.f3))
        expect(state.board.at('e1').piece.accessible_fields(state)).to include(Field.g1)
      end

      it "is not possible once the Rook has moved" do
        state = State.new(Board.from_fen('8/8/8/8/8/8/8/R3K2R')).execute(
          # move the Rook
          Field.h1.to(Field.g1)
        ).execute(
          # move it back
          Field.g1.to(Field.h1)
        )
        expect(state.board.at('e1').piece.accessible_fields(state)).to_not include(Field.g1)
      end

      it "is possible regardless if the other Rook has moved" do
        state = State.new(Board.from_fen('8/8/8/8/8/8/8/R3K2R')).execute(
          # move the Rook
          Field.a1.to(Field.a3)
        ).execute(
          # move it back
          Field.a3.to(Field.a1)
        )
        expect(state.board.at('e1').piece.accessible_fields(state)).to include(Field.g1)
      end

      it "is not possible once the King has moved" do
        state = State.new(Board.from_fen('8/8/8/8/8/8/8/R3K2R')).execute(Field.e1.to(Field.e2))
        expect(state.board.at('e2').piece.accessible_fields(state)).to_not include(Field.g1)

        # now move it back and check again
        state = state.execute(Field.e2.to(Field.e1))
        expect(state.board.at('e1').piece.accessible_fields(state)).to_not include(Field.g1)
      end

      it "moves the Rook next to the King" do
        state = State.new(Board.from_fen('8/8/8/8/8/8/8/R3K2R'))

        # Kingside
        rook_square = state.execute(Field.e1.to(Field.g1)).board.at('f1')
        expect(rook_square).to_not be_empty
        expect(rook_square.piece).to be_a(Rook)

        # Queenside
        rook_square = state.execute(Field.e1.to(Field.c1)).board.at('d1')
        expect(rook_square).to_not be_empty
        expect(rook_square.piece).to be_a(Rook)
      end

      it "is not possible when checked" do
        state = State.new(Board.from_fen('8/8/8/8/8/4r3/8/R3K2R'))

        expect(state.board.at('e1').piece.accessible_fields(state)).to_not include(Field.g1)
      end
    end

    context "a Knight" do
      it "can move unto 2 squares in the default position" do
        state = State.default
        targets = state.board.at('b1').piece.accessible_fields(state)
        expect(targets).to contain_exactly(Field.a3, Field.c3)
      end

      it "is able and only able to move in L form" do
        board = Board.new
        n = Knight.new(Team::WHITE)
        board.at(Field.c6).put(n)
        targets = n.accessible_fields(State.new(board))
        expect(targets).to contain_exactly(
          Field.a7,
          Field.b8,
          Field.d8,
          Field.e7,
          Field.a5,
          Field.b4,
          Field.d4,
          Field.e5
        )
        expect(targets.length).to be(8)
      end
    end
  end
end
