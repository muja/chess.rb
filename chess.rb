class State
  attr_writer :predecessor
  attr_accessor :board, :castle_rights, :to_move, :en_passant

  def initialize(board = Board.default, cr = CastleRights.new, ep = nil, to_move = Team::WHITE)
    @board = board
    @castle_rights = cr
    @en_passant = ep
    @to_move = to_move
  end

  def execute(move)
    self.clone.tap do |succ|
      succ.predecessor = self
      succ.to_move = self.to_move.opponent

      # execute basic move
      succ.board[*move.to.coordinates].put(succ.board[*move.from.coordinates].take)

      # update castle rights
      if move.piece.is_a? King
        # detect castling: king moves for the first time
        # meaning only way he moves to c- or g-file is by castling
        if @castle_rights[move.piece.team].any?
          rank = move.piece.team.home_rank
          if move.to.file == CastleRights::Queenside.file
            # c-file - queenside castling: put rook to d1
            succ.board[rank, move.to.file + 1].put(succ.board[rank, 0].take)
          elsif move.to.file == CastleRights::Kingside.file
            # g-file - kingside castling: put rook to f1
            succ.board[rank, move.to.file - 1].put(succ.board[rank, 7].take)
          end
        end
        # king has moved, remove all castle rights for that team
        succ.castle_rights[move.piece.team] = []
      elsif move.piece.is_a? Rook
        side = if move.from.file == 0
          CastleRights::Queenside
        elsif move.from.file == 7
          CastleRights::Kingside
        end
        succ.castle_rights[move.piece.team].delete(side) if side
      end
    end
  end

  def as_fen

  end
end

class Board
  attr_reader :fields

  def initialize
    @fields = 8.times.map do |rank|
      8.times.map {|file| Field.new(rank, file)}
    end
  end

  def [](rank, file)
    fields[rank][file]
  end

  def out_of_bounds?(rank, file)
    [rank, file].any? do |i|
      i < 0 || i >= fields.length
    end
  end

  def as_map
    "".tap do |map|
      fields.each do |rank|
        rank.each do |field|
          if field.has_piece?
            map << field.piece.an_fen
          else
            map << '.'
          end
        end
        map << "\n"
      end
    end
  end

  # Only prints board part
  def as_fen
    fields.map do |rank|
      "".tap do |line|
        empty_spaces = 0
        rank.each do |field|
          if field.has_piece?
            line << empty_spaces.to_s if empty_spaces > 0
            empty_spaces = 0
            line << field.piece.an_fen
          else
            empty_spaces += 1
          end
        end
        line << empty_spaces.to_s if empty_spaces > 0
      end
    end.join('/')
  end

  def self.from_map(text)
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

class Field
  attr_reader :file, :rank, :piece

  def initialize(rank, file, piece = nil)
    @rank = rank
    @file = file
    @piece = piece
  end

  def put(piece)
    @piece = piece
    self
  end

  def take
    @piece
  ensure
    @piece = nil
  end

  def color
    (@rank + @file) % 2 == 0 ? "w" : "b"
  end

  def empty?
    !piece
  end

  def has_piece?
    !empty?
  end

  def coordinates
    [@rank, @file]
  end

  def +(arr)
    [@rank + arr[0], @file + arr[1]]
  end

  # algebraic notation
  def an
    [(@file + 97).chr, 8 - @rank].join
  end
  alias_method :to_s, :an

  def ==(other)
    self.rank == other.rank && self.file == other.file
  end
  alias_method :eql?, :==

  def hash
    self.rank << 4 | self.file
  end
end

module MovePredicate
  class Base
    def initialize(&block)
      @block = block
    end

    def apply(context)
      @block[context]
    end
  end

  class Relative < Base
    module Directions
      NORTH   = -> (rank, file, _) { [-rank, file] }
      EAST    = -> (rank, file, _) { [file, rank] }
      SOUTH   = -> (rank, file, _) { [rank, -file] }
      WEST    = -> (rank, file, _) { [-file, -rank] }

      FORWARD = -> (rank, file, ctx) do
        (ctx.piece.team.white? ? NORTH : SOUTH)[rank, file, ctx]
      end
    end
    include Directions

    attr_writer :directions, :n, :if

    def initialize(rank, file)
      @rank = rank
      @file = file
      @directions = [FORWARD]
      @n = 1
      @if = ->(_){ true }
    end

    def all_directions
      self.clone.tap { |me| me.directions = [NORTH, EAST, SOUTH, WEST] }
    end

    def once
      self.n(1)
    end

    def twice
      self.n(2)
    end

    def indefinitely
      self.n(7)
    end

    def n(n)
      self.clone.tap { |me| me.n = n }
    end

    def if(&block)
      self.clone.tap { |me| me.if = block }
    end

    def apply(context)
      [].tap do |moves|
        @directions.each do |direct|
          current = context.source
          @n.times do
            coords = current + direct[@rank, @file, context]
            break if context.board.out_of_bounds?(*coords)
            current = context.board[*coords]
            move = Move.new(context.piece, context.source, current)
            if @if[move]
              moves << move
            end
            break if current.has_piece?
          end
        end
      end
    end
  end
  
  def RELATIVE(rank, file)
    Relative.new(rank, file)
  end

  def FORWARD(n)
    Relative.new(1, 0).n(n)
  end

  def EN_PASSANT
    Base.new do |context|
      # TODO
      []
    end
  end

  def CASTLE
    Base.new do |context|
      context.state.castle_rights[context.piece.team].map do |side|
        files = side.necessary_free_files
        predicate = files.all? do |file|
          field = context.board[context.piece.team.home_rank, file]
          field.empty? && !Utils.field_attacked?(context.board, field, context.piece.team.opponent)
        end
        if predicate
          Move.new(
            context.piece,
            context.source,
            context.board[context.piece.team.home_rank, side.file]
          )
        end
      end.compact
    end
  end
end

module CastleRights
  Queenside = Object.new
  Kingside = Object.new
  def self.new
    {
      Team::BLACK => [Queenside, Kingside],
      Team::WHITE => [Queenside, Kingside]
    }
  end

  class << Queenside
    def file
      2
    end

    def necessary_free_files
      [1, 2, 3]
    end
  end

  class << Kingside
    def file
      6
    end

    def necessary_free_files
      [5, 6]
    end
  end
end

class Team
  WHITE = Team.new
  BLACK = Team.new

  class << WHITE
    def white?
      true
    end

    def black?
      false
    end

    def opponent
      BLACK
    end

    def home_rank
      7
    end
  end

  class << BLACK
    def white?
      false
    end

    def black?
      true
    end

    def opponent
      WHITE
    end

    def home_rank
      0
    end
  end
end

class Move
  attr_reader :piece, :from, :to

  def initialize(piece, from, to)
    @piece = piece
    @from = from
    @to = to
  end

  def to_s
    [@from, @to].join " -> "
  end

  def ==(other)
    return 0
  end
  alias_method :eql?, :==

  def hash
    from.rank << 12 | from.file << 8 | to.rank << 4 | to.file
  end
end

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
    self.class.to_s[0]
  end

  # algebraic notation used in FEN
  def an_fen
    team == Team::BLACK ? an.downcase : an.upcase
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
    FORWARD(1).if { |move| move.to.empty? },
    FORWARD(2).if { |move| move.to.empty? && (move.to.rank - move.piece.team.home_rank).abs == 3 },
    RELATIVE(1, 1).if { |move| move.to.has_piece? && move.to.piece.team != move.piece.team },
    RELATIVE(1, -1).if { |move| move.to.has_piece? && move.to.piece.team != move.piece.team },
    EN_PASSANT()
  ]
end

class MoveContext < Struct.new(:board, :source, :state, :piece)
end

module Utils
  extend self
  def parse_field(input)
    file, rank = input.chars
    rank = file.bytes.first - 97
    rank = 8 - Integer(rank)
    [rank, rank]
  end

  def parse_move(board, input)
    input = input.gsub /\s|rank/, ""
    white_pat = /^\d+\.(.*)$/
    black_pat = /^\.\.+(.*)$/
    if input =~ black_pat
      black = true
    elsif input =~ white_pat
    else raise "Could not parse '#{input}'!"
    end
    actual_move = $1
    parse_move2(board, actual_move, black)
  end

  def parse_move2(board, input, black)
    input =~ /^(.*)(..)$/
    piece = $1
    piece = 'P' if piece.empty?
    piece.downcase! if black
    dest = $2
    dest = parse_field($2)
    [piece, dest]
  end

  def field_attacked?(board, field, team)
    false
  end
end
