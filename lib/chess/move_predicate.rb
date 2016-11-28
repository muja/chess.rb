module Chess
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
        self.dup.tap { |me| me.directions = [NORTH, EAST, SOUTH, WEST] }
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
        self.dup.tap { |me| me.n = n }
      end

      def if(&block)
        self.dup.tap { |me| me.if = block }
      end

      def apply(context)
        [].tap do |moves|
          @directions.each do |direct|
            current = context.source
            @n.times do
              coords = current + direct[@rank, @file, context]
              break if context.board.out_of_bounds?(*coords)
              current = context.board[*coords]
              move = Move.new(context.source, current)
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
        [].tap do |moves|
          if context.state.en_passant
            moves << Move.new(
              context.source, context.state.en_passant
            ) if [RELATIVE(1, 1), RELATIVE(1, -1)].any? do |move|
              move.apply(context).include? context.state.en_passant
            end
          end
        end
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
              context.source,
              context.board[context.piece.team.home_rank, side.file]
            )
          end
        end.compact
      end
    end
  end
end
