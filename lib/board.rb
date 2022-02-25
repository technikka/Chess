# frozen_string_literal: true

require 'colorize'
require 'colorized_string'

# the game board
class Board
  class << self
    attr_reader :squares
  end

  @squares = []

  def initialize
    create
  end

  COLUMNS = %w[a b c d e f g h].freeze
  COLORS = %i[black white].freeze

  # alter should be in pos or neg numbers
  def self.column(current_column, alter)
    index = COLUMNS.find_index(current_column)
    COLUMNS[index + alter]
  end

  def create(pos = ['a', 8], color = :white)
    return if pos == ['a', 0]

    loop do
      Board.squares << Square.new(pos.join('').to_sym, color)
      break if pos[0] == 'h'

      pos[0] = Board.column(pos[0], 1)
      color = COLORS.reject { |c| c == color }[0]
    end
    pos[1] -= 1
    create(['a', pos[1]], color)
  end

  def display
    last_row = 0
    Board.squares.each do |square|
      current_row = square.position[1].to_i
      puts "\n" if current_row < last_row
      if square.color == :white
        print white_square(square)
      else
        print black_square(square)
      end
      last_row = current_row
    end
    puts "\n"
  end

  def white_square(square)
    if square.occupied?
      color = square.occupied_by.color
      piece = Piece::SYMBOL[square.occupied_by.type]
    end
    occupied_square = " #{piece}  ".colorize(:color => color, :background => :light_blue)

    empty_square = '    '.colorize(:background => :light_blue)

    return occupied_square if square.occupied?

    empty_square
  end

  def black_square(square)
    if square.occupied?
      color = square.occupied_by.color
      piece = Piece::SYMBOL[square.occupied_by.type]
    end
    occupied_square = " #{piece}  ".colorize(:color => color, :background => :blue)

    empty_square = '    '.colorize(:background => :blue)

    return occupied_square if square.occupied?

    empty_square
  end
end
