module Chess
  class Board
    include Enumerable
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

    def each
      fields.each do |rank|
        rank.each(&:yield)
      end
    end

    def dup
      Board.new.tap do |board|
        8.times do |rank|
          8.times do |file|
            board[rank, file] = self[rank, file].dup
          end
        end
      end
    end

    protected
    def []=(rank, file, field)
      fields[rank][file] = field
    end
  end
end
