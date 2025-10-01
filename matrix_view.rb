# matrix_view.rb
# View: Handles all terminal output (rendering matrix, menus, help)

require 'colorize'

class MatrixView
  MATRIX_COLOR = :green
  BOLD_COLOR = :light_green
  FADE_COLOR = :dark_green
  CLEAR_COMMAND = Gem.win_platform? ? 'cls' : 'clear'

  def clear_screen
    system(CLEAR_COMMAND)
  end

  def render_matrix(model)
    clear_screen
    output = ""
    model.rows.times do |row|
      model.columns.times do |col|
        char = model.character_matrix[row][col]
        fade = model.fade_matrix[row][col]
        color = if model.fade_enabled && fade > 0
          case fade
          when 1 then :light_green
          when 2 then FADE_COLOR
          when 3 then :light_black
          when 4 then :black
          else MATRIX_COLOR
          end
        else
          MATRIX_COLOR
        end
        if model.bold_enabled && model.bold_matrix[row][col]
          output << char.colorize(color).bold
        else
          output << char.colorize(color)
        end
      end
      output << "\n"
    end
    print output
  end

  def display_intro(version, creator, program_name)
    clear_screen
    intro_text = "#{program_name} v#{version} by #{creator} | 'o' options"
    intro_text.each_char do |char|
      print char.colorize(MATRIX_COLOR).bold
      sleep(0.07)
    end
    sleep(2.5)
    clear_screen
  end

  def display_help(model)
    puts <<-HELP

Matrix Effect Controls:
  q - Quit the program
  s - Set speed (#{MatrixModel::MIN_SPEED}-#{MatrixModel::MAX_SPEED}, current: #{model.speed})
  b - Set bold probability (#{MatrixModel::MIN_BOLD_PROBABILITY}-#{MatrixModel::MAX_BOLD_PROBABILITY}, current: #{model.bold_probability})
  f - Set fade probability (#{MatrixModel::MIN_FADE_PROBABILITY}-#{MatrixModel::MAX_FADE_PROBABILITY}, current: #{model.fade_probability})
  d - Set duration in seconds (#{MatrixModel::MIN_DURATION}-infinite, current: #{model.duration || 'infinite'})
  c - Set number of columns (#{MatrixModel::MIN_COLUMNS}-#{MatrixModel::MAX_COLUMNS}, current: #{model.columns})
  r - Set number of rows (#{MatrixModel::MIN_ROWS}-#{MatrixModel::MAX_ROWS}, current: #{model.rows})
  t - Toggle bold effect (#{model.bold_enabled ? 'enabled' : 'disabled'})
  g - Toggle fade effect (#{model.fade_enabled ? 'enabled' : 'disabled'})
  v - Toggle speed variation (#{model.speed_variation_enabled ? 'enabled' : 'disabled'})
  n - Toggle random bold effect (#{model.random_bold_enabled ? 'enabled' : 'disabled'})
  m - Toggle random fade effect (#{model.random_fade_enabled ? 'enabled' : 'disabled'})
  h - Display this help message
  u - Check for updates (Current version : #{MatrixController::VERSION})
  x - Reset settings to original values

Press the corresponding key to execute the command.

HELP
  end
end
