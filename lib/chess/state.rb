module Chess
  class State
    attr_writer :predecessor
    attr_accessor :board, :castle_rights, :to_move, :en_passant

    def initialize(board = Board.new, cr = CastleRights.new, ep = nil, to_move = Team::WHITE)
      @board = board
      @castle_rights = cr
      @en_passant = ep
      @to_move = to_move
    end

    def execute(move)
      self.dup.tap do |succ|
        succ.predecessor = self
        succ.to_move = self.to_move.opponent
        succ.en_passant = nil
        piece = board.at(move.from).piece

        # update castle rights
        if piece.is_a? King
          # detect castling: king moves for the first time
          # meaning only way he moves to c- or g-file is by castling
          if @castle_rights[piece.team].any?
            rank = piece.team.home_rank
            if move.to.file == CastleRights::Queenside.file
              # c-file - queenside castling: put rook to d1
              succ.board[rank, move.to.file + 1].put(succ.board[rank, 0].take)
            elsif move.to.file == CastleRights::Kingside.file
              # g-file - kingside castling: put rook to f1
              succ.board[rank, move.to.file - 1].put(succ.board[rank, 7].take)
            end
          end
          # king has moved, remove all castle rights for that team
          succ.castle_rights[piece.team] = []
        elsif piece.is_a? Rook
          side = if move.from.file == 0
            CastleRights::Queenside
          elsif move.from.file == 7
            CastleRights::Kingside
          end
          succ.castle_rights[piece.team].delete(side) if side
        elsif piece.is_a? Pawn
          # detect en passant
          # capturing move on empty field = en passant
          if move.to.file != move.from.file && move.to.empty?
            # field of captured pawn, remove it
            succ.board[move.from.rank, move.to.file].take

            # double step, enable en_passant
          elsif (move.from.rank - move.to.rank).abs == 2
            skipped_rank = [move.from.rank, move.to.rank].max - 1
            succ.en_passant = succ.board[skipped_rank, move.from.file]
          end
        end

        # execute basic move
        succ.board[*move.to.coordinates].put(succ.board[*move.from.coordinates].take)
      end
    end

    def dup
      super.tap do |copy|
        copy.board = board.dup
        copy.castle_rights = Hash[castle_rights.map{|k, v| [k, v.dup]}]
      end
    end

    def self.default
      State.new(Board.default)
    end
  end
end
