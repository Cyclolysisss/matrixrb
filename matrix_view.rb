if $0 == __FILE__
  warn "This file is intended to be used as part of the MatrixRB program and should not be run directly. please run 'ruby main.rb' instead."
  exit 1
end

# matrix_view.rb
# View: Handles all terminal output (rendering matrix, menus, help)

require 'colorize'

class MatrixView
  MATRIX_COLOR = :green
  BOLD_COLOR = :light_green
  FADE_COLOR = :dark_green
  # Use ANSI escape codes to move cursor to top-left and avoid full screen clear
  def move_cursor_top_left
    print "\e[H"
  end

  def clear_screen
    print "\e[2J\e[H"
  end

  def get_terminal_size
    if Gem.win_platform?
      require 'io/console'
      IO.console.winsize.reverse # [columns, rows]
    else
      require 'io/console'
      IO.console.winsize.reverse
    end
  rescue
    [80, 24] # fallback
  end

  def render_matrix(model)
    cols, rows = get_terminal_size
    # Only update if size changed
    if model.columns != cols || model.rows != rows
      model.columns = cols
      model.rows = rows
      model.initialize_matrices
    end
    move_cursor_top_left
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

  def display_intro(version, creator, program_name, version_check_result = nil)
    move_cursor_top_left
    print "\e[2J" # clear screen once at start
    intro_text = "#{program_name} v#{version} by #{creator} | 'o' options"
    intro_text.each_char do |char|
      print char.colorize(MATRIX_COLOR).bold
      sleep(0.07)
    end
    epilepsy_warning_text = "\n\n!! Warning !!: I do not recommend setting speed below 0.5 if you are prone to seizures or epilepsy !! I disclaim all responsibility for any health issues caused by using this program !!"
    print epilepsy_warning_text.colorize(:red).bold
    sleep(4)
    if version_check_result
      version_check_text = "\n\n#{version_check_result}"
      print version_check_text.colorize(MATRIX_COLOR).bold
      sleep(4)
    else
      sleep(2.5)
    end
    move_cursor_top_left
    print "\e[2J"
  end

  def display_help(model)
    move_cursor_top_left
    puts <<-HELP

Matrix Effect Controls:
  q - Quit the program
  w - Save config to file
  l - Load config from file
  s - Set speed (#{MatrixModel::MIN_SPEED}-#{MatrixModel::MAX_SPEED}, current: #{model.speed}) (WARNING: very low speeds may cause high CPU usage if your computer is lagging I suggest increasing speed, for slower machines I recommend not to set speed below 0.5)
  b - Set bold probability (#{MatrixModel::MIN_BOLD_PROBABILITY}-#{MatrixModel::MAX_BOLD_PROBABILITY}, current: #{model.bold_probability})
  f - Set fade probability (#{MatrixModel::MIN_FADE_PROBABILITY}-#{MatrixModel::MAX_FADE_PROBABILITY}, current: #{model.fade_probability})
  d - Set duration in seconds (#{MatrixModel::MIN_DURATION}-infinite, current: #{model.duration || 'infinite'})
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
