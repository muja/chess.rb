require 'chess'

RSpec.describe Chess, "#field_attackers" do
  it "attacks" do
    s = Chess::State.default
    expect(
      Chess::Utils.field_attackers(s.board.at('c3'), on: s, by: Chess::Team::WHITE)
    ).to contain_exactly(
      s.board.at('b1').piece,
      s.board.at('b2').piece,
      s.board.at('d2').piece
    )
  end
end
