# frozen_string_literal: true

# handles the behavior of a move made by player
class Move
  include MoveError
  attr_reader :player, :move, :piece, :landing, :opponent

  def initialize(player, opponent)
    @player = player
    @opponent = opponent
    initiate
    execute
  end

  def set_vars
    @move = player_input
    @piece = Square.find_by_pos(move[0]).occupied_by
    @landing = Square.find_by_pos(move[1])
  end

  def initiate
    set_vars
    return piece.take_en_passant(opponent, landing) if passant_move?

    error = evaluate
    return unless error

    Display.move_error(error)
    initiate
  end

  def evaluate
    general_error.each do |method, response|
      conditions_pass = send(method)
      return response unless conditions_pass
    end
    return check_error unless check_error.nil?
    return nil unless piece.is_a?(Pawn)

    pawn_error
  end

  def path(piece = @piece, position = landing.pos)
    way = piece.moves
               .select { |array| array.include?(position) }
               .flatten
    index = way.find_index(position)
    way[0..index]
  end

  def move_gives_check?
    player.pieces.each do |pp|
      next unless pp.moves.any? { |m| m.include?(opponent.king_pos) }

      return true if path_clear?(pp, opponent.king_pos)
    end
    false
  end

  def execute
    capture if capture?
    update_state
    return mate if mated?

    give_check if move_gives_check?
    pawn_privelage if piece.is_a?(Pawn)
  end

  def update_state
    piece.current_pos = landing.pos
    landing.occupied_by = piece
    Square.find_by_pos(move[0]).update
  end

  def pawn_privelage
    if piece.giving_en_passant?(move[0])
      piece.give_en_passant
    elsif piece.promotion?
      piece.promote(player)
    end
  end

  def passant_move?
    piece.is_a?(Pawn) &&
      piece.taking_en_passant?(landing.pos)
  end

  def in_check?
    player.in_check == true
  end

  def remove_check
    player.in_check = false
  end

  def give_check
    opponent.in_check = true
    puts "*** #{opponent.color.capitalize} is in check ***"
  end

  def capture?
    landing.occupied? &&
      landing.occupied_by.color != player.color
  end

  def capture
    opponent.piece_taken(landing.occupied_by)
  end

  def mated?
    opponent.graveyard.any? { |piece| piece.is_a?(King) }
  end

  def mate
    Game.mate = true
    puts "*** #{player.color.capitalize} wins! ***"
  end

  def player_input
    puts 'Move: '
    input = gets.chomp.split(' ').map(&:to_sym)
    return input if valid?(input)

    player_input
  end

  def valid?(input)
    Square.find_by_pos(input[0])
    Square.find_by_pos(input[1])
  end
end
