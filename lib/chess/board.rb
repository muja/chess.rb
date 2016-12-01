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

    def where(piece)
      self.find{ |field| field.piece == piece }
    end

    def king_square(team)
      where(King.new(team))
    end

    def out_of_bounds?(rank, file)
      [rank, file].any? do |i|
        i < 0 || i >= fields.length
      end
    end

    def each
      fields.each do |rank|
        rank.each do |field|
          yield field
        end
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
