# matrix_model.rb
# Model: Handles matrix state, settings, and update logic

require 'securerandom'

class MatrixModel
  attr_accessor :columns, :rows, :speed, :bold_probability, :fade_probability, :duration,
                :bold_enabled, :fade_enabled, :speed_variation_enabled, :random_bold_enabled, :random_fade_enabled
  attr_reader :character_matrix, :fade_matrix, :bold_matrix, :column_drops

  CHARACTER_SET = (('0'..'9').to_a + ('A'..'Z').to_a + ('a'..'z').to_a + ['@', '#', '$', '%', '&', '*', '+', '-', '=', '?', '!', '|', '/', ';', '.', ',', '`', '^']).shuffle
  MIN_SPEED = 0.01
  MAX_SPEED = 1.0
  MIN_BOLD_PROBABILITY = 0.0
  MAX_BOLD_PROBABILITY = 1.0
  MIN_FADE_PROBABILITY = 0.0
  MAX_FADE_PROBABILITY = 1.0
  MIN_COLUMNS = 20
  MAX_COLUMNS = 200
  MIN_ROWS = 10
  MAX_ROWS = 100
  MIN_DURATION = 1

  def initialize(columns: 80, rows: 24, speed: 0.1, bold_probability: 0.1, fade_probability: 0.05, duration: nil,
                 bold_enabled: true, fade_enabled: true, speed_variation_enabled: true, random_bold_enabled: true, random_fade_enabled: true)
    @columns = columns
    @rows = rows
    @speed = speed
    @bold_probability = bold_probability
    @fade_probability = fade_probability
    @duration = duration
    @bold_enabled = bold_enabled
    @fade_enabled = fade_enabled
    @speed_variation_enabled = speed_variation_enabled
    @random_bold_enabled = random_bold_enabled
    @random_fade_enabled = random_fade_enabled
    initialize_matrices
  end

  def initialize_matrices
    @character_matrix = Array.new(@rows) { Array.new(@columns) { ' ' } }
    @fade_matrix = Array.new(@rows) { Array.new(@columns, 0) }
    @bold_matrix = Array.new(@rows) { Array.new(@columns, false) }
    @column_drops = Array.new(@columns) { rand(@rows) }
  end

  def update_matrices
    @columns.times do |col|
      drop_row = @column_drops[col]
      if drop_row < @rows
        @character_matrix[drop_row][col] = CHARACTER_SET.sample
        @fade_matrix[drop_row][col] = 0
        @bold_matrix[drop_row][col] = true
      end
      (0...@rows).each do |row|
        if row != drop_row
          @fade_matrix[row][col] = [@fade_matrix[row][col] + 1, 4].min if @fade_enabled
          @bold_matrix[row][col] = false
        end
      end
      if rand < 0.02 || drop_row >= @rows + rand(5)
        @column_drops[col] = 0
      else
        @column_drops[col] += 1
      end
    end
    if @random_bold_enabled
      (@rows * @columns * 0.02).to_i.times do
        r, c = rand(@rows), rand(@columns)
        @bold_matrix[r][c] = !@bold_matrix[r][c]
      end
    end
    if @random_fade_enabled
      (@rows * @columns * 0.01).to_i.times do
        r, c = rand(@rows), rand(@columns)
        @fade_matrix[r][c] = [@fade_matrix[r][c] + 1, 4].min
      end
    end
  end
end
