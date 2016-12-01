require 'chess'

module Chess
  RSpec.describe Notation::FEN do
    it "returns correct FEN for default starting position" do
      expect(Board.default.fen).to eq("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR")
    end

    it "is symmetric" do
      expect(Board.default.fen).to eq(Board.from_fen(Board.default.fen).fen)
    end
  end
end
