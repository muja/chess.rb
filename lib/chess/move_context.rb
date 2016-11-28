module Chess
  class MoveContext < Struct.new(:board, :source, :state, :piece)
  end
end
