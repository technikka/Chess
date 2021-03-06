# frozen_string_literal: true

# evaluates the validity of a move.
class Evaluator
  attr_reader :player, :opponent, :piece, :landing, :castling

  def initialize(move)
    @player = move.player
    @opponent = move.opponent
    @piece = move.piece
    @landing = move.landing
    @castling = move.castling
  end

  def error
    error_types.each do |type|
      error = send(type)
      return error if error
      break if castling && type == :castling_error
    end
    nil
  end

  def path_clear?(piece = @piece, position = landing.pos)
    path(piece, position).each do |pos|
      next if pos == position

      return false unless square_clear(pos)
    end
    true
  end

  private

  def error_types
    %i[elemental_error castling_error general_error check_error pawn_error]
  end

  def elemental_error
    return :no_piece unless piece?
    return [:wrong_color, player.color.to_s.capitalize] unless players_piece?
  end

  def general_error
    return [:invalid_movement, piece.class] unless valid_movement?
    return [:obstructed_path, landing.pos] unless path_clear?
    return :occupied_landing unless unoccupied_landing?
  end

  def check_error
    if player.in_check && puts_in_check?
      :in_check
    elsif puts_in_check?
      :checks_self
    end
  end

  def pawn_error
    return false unless piece.is_a?(Pawn)

    if pawn_diagonal? && !pawn_capture?
      :illegal_pawn
    elsif pawn_blocked?
      :blocked
    end
  end

  def castling_error
    return unless piece.is_a?(King)

    castler = Castler.new(piece, player, opponent, landing)
    return unless castler.attempt?

    return :kings_moved unless piece.first_move?
    return :rooks_moved unless castler.rook.first_move?
    return [:obstructed_path, landing.pos] unless path_clear?(piece, castler.rook.current_pos)
    return :castling_in_check if player.in_check == true
    return :checks_self if puts_in_check?
    return :illegal_jump if castler.jumped_square_under_attack?
  end

  def pawn_diagonal?
    piece.is_a?(Pawn) &&
      landing.pos[0] != piece.current_pos[0]
  end

  def pawn_capture?
    pawn_diagonal? && landing.occupied?
  end

  def pawn_blocked?
    !pawn_diagonal? && landing.occupied?
  end

  def piece?
    return false if piece.nil?

    true
  end

  def players_piece?
    piece.color == player.color
  end

  def valid_movement?
    piece.moves.any? { |m| m.include?(landing.pos) }
  end

  def path(piece = @piece, position = landing.pos)
    way = piece.moves
               .select { |array| array.include?(position) }
               .flatten
    index = way.find_index(position)
    way[0..index]
  end

  # path_clear? helper
  def square_clear(pos)
    square = Square.find_by_pos(pos)
    # square's currently clear or will be if move succeeds.
    square.occupied_by.nil? || square.occupied_by == @piece
  end

  def unoccupied_landing?
    landing.occupied_by.nil? ||
      landing.occupied_by.color != player.color
  end

  def puts_in_check?(king_pos = player.king_pos)
    king_pos = landing.pos if piece.is_a?(King)

    opponent.pieces.each do |op|
      next unless op.moves.any? { |m| m.include?(king_pos) }

      return true if path_clear?(op, king_pos)
    end
    false
  end
end
