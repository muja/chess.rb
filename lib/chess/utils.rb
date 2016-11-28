module Chess
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
end
