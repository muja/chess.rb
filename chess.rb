class State
  def initialize(board, castle_rights, en_passant)
    @board = board
    @castle = castle_rights
    @ep = en_passant
  end

  def move(src, dst)
    
  end
end

class Field
  attr_reader :x, :y, :piece

  def initialize(x, y, piece = nil)
    @x = x
    @y = y
    @piece = piece
  end

  def put(piece)
    @piece = piece
    self
  end

  def color
    (@x + @y) % 2 == 0 ? "w" : "b"
  end

  def empty?
    !piece
  end

  def has_piece?
    !empty?
  end

  def +(arr)
    [@x + arr[0], @y + arr[1]]
  end

  # algebraic notation
  def an
    [(@x + 97).chr, 8 - @y].join
  end
  alias :to_s :an

  def ==(other)
    self.x == other.x && self.y == other.y
  end
  alias :eql? :==
end

class Board
  attr_reader :fields

  def initialize
    @fields = 8.times.map do |x|
      8.times.map {|y| Field.new(x, y)}
    end
  end

  def [](x, y)
    raise IndexError.new([x, y]) if out_of_bounds? x, y
    fields[x][y]
  end

  def out_of_bounds?(x, y)
    [x, y].any? do |i|
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

  # Only prints
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
      text.lines.each_with_index do |line, x|
        line.strip.chars.each_with_index do |char, y|
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
          board[x, y].put(piece)
        end
      end
    end
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
      NORTH   = -> (x, y, _) { [-x, y] }
      EAST    = -> (x, y, _) { [y, x] }
      SOUTH   = -> (x, y, _) { [x, -y] }
      WEST    = -> (x, y, _) { [-y, -x] }

      FORWARD = -> (x, y, ctx) do
        (ctx.piece.team.white? ? NORTH : SOUTH)[x, y, ctx]
      end
    end
    include Directions

    attr_writer :directions, :n, :if

    def initialize(x, y)
      @x = x
      @y = y
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
      [].tap do |destinations|
        @directions.each do |direct|
          field = context.source
          @n.times do
            coords = field + direct[@x, @y, context]
            break if context.board.out_of_bounds?(*coords)
            field = context.board[*coords]
            if @if[field, context.source]
              destinations << field
              break if field.has_piece?
            end
          end
        end
      end
    end
  end
  
  def RELATIVE(x, y)
    Relative.new(x, y)
  end

  def FORWARD(n)
    Relative.new(1, 0).n(n)
  end

  def EN_PASSANT()
    Base.new do |context|
      # TODO
      []
    end
  end

  def CASTLE()
    Base.new do |context|
      # TODO
      []
    end
  end
end

class Team
  WHITE = Team.new
  class << WHITE
    def white?
      true
    end

    def black?
      false
    end
  end

  BLACK = Team.new
  class << BLACK
    def white?
      false
    end

    def black?
      true
    end
  end
end

class Piece
  extend MovePredicate

  attr_reader :team
  def initialize(team)
    @team = team
  end

  def possible_moves(context)
    self.class::MOVES.map do |move|
      move.apply(context)
    end.flatten.reject do |field|
      context.piece.team == field.piece.team
    end
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
    FORWARD(1).if { |field| field.empty? },
    # FORWARD(2).if { |field, source| source == self.origin && field.empty? },
    RELATIVE(1, 1).if { |field| field.has_piece? && field.piece.team != team },
    RELATIVE(1, -1).if { |field| field.has_piece? && field.piece.team != team },
    EN_PASSANT()
  ]
end

class MoveContext < Struct.new(:board, :source, :piece)
end

class Utils
  def parse_field(input)
    file, rank = input.chars
    x = file.bytes.first - 97
    rank = 8 - Integer(rank)
    [x, rank]
  end

  def parse_move(board, input)
    input = input.gsub /\s|x/, ""
    white_pat = /^\d+\.(.*)$/
    black_pat = /^\.\.\.(.*)$/
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
end
