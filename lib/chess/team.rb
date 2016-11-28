module Chess
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
end
