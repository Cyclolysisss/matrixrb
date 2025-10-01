# matrix_controller.rb
# Controller: Handles user input, program flow, and coordination between model and view

require_relative 'matrix_model'
require_relative 'matrix_view'
require 'io/console'

class MatrixController
  VERSION = '1.0.7'
  CREATOR = 'Cyclolysis'
  PROGRAM_NAME = 'MatrixRB'

  def initialize
    @model = MatrixModel.new
    @view = MatrixView.new
    @stop = false
    @start_time = nil
  end

  def run
    @view.display_intro(VERSION, CREATOR, PROGRAM_NAME)
    @model.initialize_matrices
    @start_time = Time.now
    begin
      STDIN.echo = false
      STDIN.raw!
      loop do
        break if @stop
        if IO.select([STDIN], nil, nil, 0.01)
          char = STDIN.getc rescue nil
          if char && char.downcase == 'o'
            STDIN.cooked! if STDIN.respond_to?(:cooked!)
            show_options_menu
            STDIN.raw! if STDIN.respond_to?(:raw!)
          elsif char == 'q'
            @stop = true
            break
          end
        end
        if @model.duration && (Time.now - @start_time) >= @model.duration
          puts "\nDuration reached. Exiting..."
          break
        end
        @model.update_matrices
        @view.render_matrix(@model)
        if @model.respond_to?(:debug_mode) && @model.debug_mode
          puts "[DEBUG] Terminal size: cols=#{@model.columns}, rows=#{@model.rows}"
          puts "[DEBUG] First row: #{@model.character_matrix[0].inspect}"
        end 
        sleep_time = if @model.speed_variation_enabled
                       rand(@model.speed * 0.5..@model.speed * 1.5)
                     else
                       @model.speed
                     end
        sleep(sleep_time)
      end
    ensure
      STDIN.cooked! if STDIN.respond_to?(:cooked!)
      STDIN.echo = true
    end
    @view.clear_screen
    puts "#{PROGRAM_NAME} terminated. Goodbye!"
  end

  def show_options_menu
    loop do
      @view.clear_screen
      @view.display_help(@model)
      puts "\nEnter a command (or press Enter to return to the matrix):"
      print "> "
      input = STDIN.gets&.chomp
      break if input.nil? || input.empty?
      case input
      when 'q'
        @stop = true
        break
      when 'w'
        print "\nSave config to file (default: matrix_config.yml): "
        file = STDIN.gets&.chomp
        file = 'matrix_config.yml' if file.nil? || file.empty?
        begin
          @model.save_config(file, VERSION)
          puts "Config saved to #{file}."
        rescue => e
          puts "Failed to save config: #{e.message}"
        end
      when 'l'
        print "\nLoad config from file (default: matrix_config.yml): "
        file = STDIN.gets&.chomp
        file = 'matrix_config.yml' if file.nil? || file.empty?
        begin
          loaded = @model.load_config(file, VERSION)
          if loaded
            puts "Config loaded from #{file}."
            if @model.debug_mode
              puts "[DEBUG] Debug mode enabled from config."
              puts "[DEBUG] Model settings:"
              puts @model.inspect
            end
          end
        rescue => e
          puts "Failed to load config: #{e.message}"
        end
      when 's'
        print "\nNew speed (#{MatrixModel::MIN_SPEED}-#{MatrixModel::MAX_SPEED}, current: #{@model.speed}): "
        val = STDIN.gets&.chomp
        if val =~ /^\d*\.?\d+$/
          new_speed = val.to_f
          if new_speed >= MatrixModel::MIN_SPEED && new_speed <= MatrixModel::MAX_SPEED
            @model.speed = new_speed
            puts "Speed updated: #{@model.speed}"
          else
            puts "Value out of bounds."
          end
        else
          puts "Invalid input."
        end
      when 'b'
        print "\nNew bold probability (#{MatrixModel::MIN_BOLD_PROBABILITY}-#{MatrixModel::MAX_BOLD_PROBABILITY}, current: #{@model.bold_probability}): "
        val = STDIN.gets&.chomp
        if val =~ /^\d*\.?\d+$/
          new_bold = val.to_f
          if new_bold >= MatrixModel::MIN_BOLD_PROBABILITY && new_bold <= MatrixModel::MAX_BOLD_PROBABILITY
            @model.bold_probability = new_bold
            puts "Bold probability updated: #{@model.bold_probability}"
          else
            puts "Value out of bounds."
          end
        else
          puts "Invalid input."
        end
      when 'f'
        print "\nNew fade probability (#{MatrixModel::MIN_FADE_PROBABILITY}-#{MatrixModel::MAX_FADE_PROBABILITY}, current: #{@model.fade_probability}): "
        val = STDIN.gets&.chomp
        if val =~ /^\d*\.?\d+$/
          new_fade = val.to_f
          if new_fade >= MatrixModel::MIN_FADE_PROBABILITY && new_fade <= MatrixModel::MAX_FADE_PROBABILITY
            @model.fade_probability = new_fade
            puts "Fade probability updated: #{@model.fade_probability}"
          else
            puts "Value out of bounds."
          end
        else
          puts "Invalid input."
        end
      when 'd'
        print "\nNew duration in seconds (#{MatrixModel::MIN_DURATION}-infinite, current: #{@model.duration || 'infinite'}): "
        val = STDIN.gets&.chomp
        if val =~ /^\d*\.?\d+$/
          new_dur = val.to_f
          if new_dur >= MatrixModel::MIN_DURATION
            @model.duration = new_dur
            puts "Duration updated: #{@model.duration}"
          else
            puts "Value out of bounds."
          end
        else
          puts "Invalid input."
        end
#  ------------------------------------------Removed because it is automatically set to match terminal size------------------------------------------
#      when 'c'
#        print "\nNew columns (#{MatrixModel::MIN_COLUMNS}-#{MatrixModel::MAX_COLUMNS}, current: #{@model.columns}): "
#        val = STDIN.gets&.chomp
#        if val =~ /^\d+$/
#          new_col = val.to_i
#          if new_col >= MatrixModel::MIN_COLUMNS && new_col <= MatrixModel::MAX_COLUMNS
#            @model.columns = new_col
#            @model.initialize_matrices
#            puts "Columns updated: #{@model.columns}"
#          else
#            puts "Value out of bounds."
#          end
#        else
#          puts "Invalid input."
#        end
#      when 'r'
#        print "\nNew rows (#{MatrixModel::MIN_ROWS}-#{MatrixModel::MAX_ROWS}, current: #{@model.rows}): "
#        val = STDIN.gets&.chomp
#        if val =~ /^\d+$/
#          new_row = val.to_i
#          if new_row >= MatrixModel::MIN_ROWS && new_row <= MatrixModel::MAX_ROWS
#            @model.rows = new_row
#            @model.initialize_matrices
#            puts "Rows updated: #{@model.rows}"
#          else
#            puts "Value out of bounds."
#          end
#        else
#          puts "Invalid input."
#        end
#  -----------------------------------------------------------------------------------------------------------------------------------------------------------
      when 't'
        @model.bold_enabled = !@model.bold_enabled
        puts "Bold effect #{@model.bold_enabled ? 'enabled' : 'disabled'}."
      when 'g'
        @model.fade_enabled = !@model.fade_enabled
        puts "Fade effect #{@model.fade_enabled ? 'enabled' : 'disabled'}."
      when 'v'
        @model.speed_variation_enabled = !@model.speed_variation_enabled
        puts "Speed variation #{@model.speed_variation_enabled ? 'enabled' : 'disabled'}."
      when 'n'
        @model.random_bold_enabled = !@model.random_bold_enabled
        puts "Random bold effect #{@model.random_bold_enabled ? 'enabled' : 'disabled'}."
      when 'm'
        @model.random_fade_enabled = !@model.random_fade_enabled
        puts "Random fade effect #{@model.random_fade_enabled ? 'enabled' : 'disabled'}."
      when 'h'
        @view.display_help(@model)
      when 'u'
        puts "\nChecking for updates..."
        begin
          require 'open-uri'
          latest_version = URI.open('https://raw.githubusercontent.com/Cyclolysisss/MatrixRB/main/VERSION').read.strip
          if latest_version != VERSION
            puts "New version available: #{latest_version} (you are using version v#{VERSION})."
            puts "Visit https://github.com/Cyclolysisss/MatrixRB for more information and to update (an Internet connection is required)."
          else
            puts "You are using the latest version (v#{VERSION})."
          end
        rescue => e
          puts "Failed to check for updates: #{e.message}"
        end
      when 'x'
        # Reset to defaults
        @model = MatrixModel.new
        puts "Settings reset."
      else
        puts "Unknown command. Type 'h' for help."
      end
      puts "Press Enter to continue..."
      STDIN.gets
    end
  end
end
