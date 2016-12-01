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

      def initialize(rank, file)
        @positions = [[rank, file]]
        @directions = [FORWARD]
        @steps = 1
        @if = ->(_){ true }
        @if_outset = false
        @en_passant = false
      end

      def or(rank, file)
        self.dup.tap { |me| me.positions = @positions + [[rank, file]] }
      end

      def capture_only
        self.if do |to|
          to.has_piece? && to.piece.team != self.team
        end
      end

      def non_capturing
        self.if(&:empty?)
      end

      def all_directions
        self.dup.tap { |me| me.directions = [NORTH, EAST, SOUTH, WEST] }
      end

      def once
        self.steps(1)
      end

      def twice
        self.steps(2)
      end

      def indefinitely
        self.steps(7)
      end

      def steps(steps)
        self.dup.tap { |me| me.steps = steps }
      end

      def if(&block)
        self.dup.tap { |me| me.if = block }
      end

      def if_outset
        self.dup.tap { |me| me.if_outset = true }
      end

      def en_passant
        self.dup.tap { |me| me.en_passant = true }
      end

      def apply(context)
        [].tap do |targets|
          from = context.board.where(context.piece)
          if @if_outset
            field = Board.default.at(from)
            next if field.empty? || field.piece.class != context.piece.class
          end
          @directions.each do |direct|
            @positions.each do |rank, file|
              current = from
              @steps.times do
                coords = current + direct[rank, file, context]
                break if context.board.out_of_bounds?(*coords)
                current = context.board[*coords]
                targets << current if context.piece.instance_exec(current, &@if) || (
                  @en_passant && context.state.en_passant == current
                )
                break if current.has_piece?
              end
            end
          end
        end
      end

      def dup
        super.tap do |me|
          me.directions = @directions.dup
          me.positions = @positions.dup
        end
      end

      protected
      attr_writer :directions, :steps, :if, :if_outset, :positions, :en_passant
    end

    def RELATIVE(rank, file)
      Relative.new(rank, file)
    end

    def FORWARD(steps)
      Relative.new(1, 0).steps(steps)
    end

    def CASTLE
      Base.new do |context|
        context.state.castle_rights[context.piece.team].map do |side|
          files = side.necessary_free_files
          fields_clean = files.all? do |file|
            field = context.board[context.piece.team.home_rank, file]
            field.empty? && !Utils.field_attacked?(
              field, on: context.board, by: context.piece.team.opponent
            )
          end
          context.board[context.piece.team.home_rank, side.file] if fields_clean
        end.compact
      end
    end
  end
end
