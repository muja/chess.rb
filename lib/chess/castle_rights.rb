module Chess
  module CastleRights
    Queenside = Object.new
    Kingside = Object.new
    def self.new
      {
        Team::BLACK => [Queenside, Kingside],
        Team::WHITE => [Queenside, Kingside]
      }
    end

    class << Queenside
      def file
        2
      end

      def necessary_free_files
        [1, 2, 3]
      end
    end

    class << Kingside
      def file
        6
      end

      def necessary_free_files
        [5, 6]
      end
    end
  end
end
