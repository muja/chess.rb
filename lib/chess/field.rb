module Chess
  class Field
    attr_reader :rank, :file, :piece

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

    def to(other)
      Move.new(self, other)
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

    def ==(other)
      self.rank == other.rank && self.file == other.file
    end
    alias_method :eql?, :==

    def hash
      self.rank << 4 | self.file
    end

    def dup
      super.tap do |copy|
        copy.piece = piece.dup if piece
      end
    end

    protected
    attr_writer :piece
  end
end
