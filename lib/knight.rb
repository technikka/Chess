# frozen_string_literal: true

# defines the Knights behavior
class Knight
  attr_reader :type, :color, :start_pos, :current_pos

  def initialize(type, color, pos)
    @type = type
    @color = color
    @pos = pos
    @current_pos = pos
  end
end