module Chess
  class Move
    attr_reader :from, :to

    def initialize(from, to)
      @from = from
      @to = to
    end

    def piece
      from.piece
    end

    def to_s
      [@from, @to].join " -> "
    end

    def ==(other)
      return self.from == other.from && self.to == other.to
    end
    alias_method :eql?, :==

    def hash
      from.rank << 12 | from.file << 8 | to.rank << 4 | to.file
    end
  end
end
