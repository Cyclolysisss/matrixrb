# matrix_controller.rb
# Controller: Handles user input, program flow, and coordination between model and view

require_relative 'matrix_model'
require_relative 'matrix_view'
require 'io/console'

class MatrixController
  VERSION = '1.0.1'
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
      puts "\nEntrez une commande (ou appuyez sur Entrée pour revenir à la matrice) :"
      print "> "
      input = STDIN.gets&.chomp
      break if input.nil? || input.empty?
      case input
      when 'q'
        @stop = true
        break
      when 's'
        print "\nNouvelle vitesse (#{MatrixModel::MIN_SPEED}-#{MatrixModel::MAX_SPEED}, actuel: #{@model.speed}): "
        val = STDIN.gets&.chomp
        if val =~ /^\d*\.?\d+$/
          new_speed = val.to_f
          if new_speed >= MatrixModel::MIN_SPEED && new_speed <= MatrixModel::MAX_SPEED
            @model.speed = new_speed
            puts "Vitesse mise à jour: #{@model.speed}"
          else
            puts "Valeur hors limites."
          end
        else
          puts "Entrée invalide."
        end
      when 'b'
        print "\nNouvelle probabilité bold (#{MatrixModel::MIN_BOLD_PROBABILITY}-#{MatrixModel::MAX_BOLD_PROBABILITY}, actuel: #{@model.bold_probability}): "
        val = STDIN.gets&.chomp
        if val =~ /^\d*\.?\d+$/
          new_bold = val.to_f
          if new_bold >= MatrixModel::MIN_BOLD_PROBABILITY && new_bold <= MatrixModel::MAX_BOLD_PROBABILITY
            @model.bold_probability = new_bold
            puts "Probabilité bold mise à jour: #{@model.bold_probability}"
          else
            puts "Valeur hors limites."
          end
        else
          puts "Entrée invalide."
        end
      when 'f'
        print "\nNouvelle probabilité fade (#{MatrixModel::MIN_FADE_PROBABILITY}-#{MatrixModel::MAX_FADE_PROBABILITY}, actuel: #{@model.fade_probability}): "
        val = STDIN.gets&.chomp
        if val =~ /^\d*\.?\d+$/
          new_fade = val.to_f
          if new_fade >= MatrixModel::MIN_FADE_PROBABILITY && new_fade <= MatrixModel::MAX_FADE_PROBABILITY
            @model.fade_probability = new_fade
            puts "Probabilité fade mise à jour: #{@model.fade_probability}"
          else
            puts "Valeur hors limites."
          end
        else
          puts "Entrée invalide."
        end
      when 'd'
        print "\nNouvelle durée en secondes (#{MatrixModel::MIN_DURATION}-infinite, actuel: #{@model.duration || 'infinite'}): "
        val = STDIN.gets&.chomp
        if val =~ /^\d*\.?\d+$/
          new_dur = val.to_f
          if new_dur >= MatrixModel::MIN_DURATION
            @model.duration = new_dur
            puts "Durée mise à jour: #{@model.duration}"
          else
            puts "Valeur hors limites."
          end
        else
          puts "Entrée invalide."
        end
      when 'c'
        print "\nNouvelles colonnes (#{MatrixModel::MIN_COLUMNS}-#{MatrixModel::MAX_COLUMNS}, actuel: #{@model.columns}): "
        val = STDIN.gets&.chomp
        if val =~ /^\d+$/
          new_col = val.to_i
          if new_col >= MatrixModel::MIN_COLUMNS && new_col <= MatrixModel::MAX_COLUMNS
            @model.columns = new_col
            @model.initialize_matrices
            puts "Colonnes mises à jour: #{@model.columns}"
          else
            puts "Valeur hors limites."
          end
        else
          puts "Entrée invalide."
        end
      when 'r'
        print "\nNouvelles lignes (#{MatrixModel::MIN_ROWS}-#{MatrixModel::MAX_ROWS}, actuel: #{@model.rows}): "
        val = STDIN.gets&.chomp
        if val =~ /^\d+$/
          new_row = val.to_i
          if new_row >= MatrixModel::MIN_ROWS && new_row <= MatrixModel::MAX_ROWS
            @model.rows = new_row
            @model.initialize_matrices
            puts "Lignes mises à jour: #{@model.rows}"
          else
            puts "Valeur hors limites."
          end
        else
          puts "Entrée invalide."
        end
      when 't'
        @model.bold_enabled = !@model.bold_enabled
        puts "Effet bold #{@model.bold_enabled ? 'activé' : 'désactivé'}."
      when 'g'
        @model.fade_enabled = !@model.fade_enabled
        puts "Effet fade #{@model.fade_enabled ? 'activé' : 'désactivé'}."
      when 'v'
        @model.speed_variation_enabled = !@model.speed_variation_enabled
        puts "Variation vitesse #{@model.speed_variation_enabled ? 'activée' : 'désactivée'}."
      when 'n'
        @model.random_bold_enabled = !@model.random_bold_enabled
        puts "Effet bold aléatoire #{@model.random_bold_enabled ? 'activé' : 'désactivé'}."
      when 'm'
        @model.random_fade_enabled = !@model.random_fade_enabled
        puts "Effet fade aléatoire #{@model.random_fade_enabled ? 'activé' : 'désactivé'}."
      when 'h'
        @view.display_help(@model)
      when 'x'
        # Reset to defaults
        @model = MatrixModel.new
        puts "Paramètres réinitialisés."
      else
        puts "Commande inconnue. Tapez 'h' pour l'aide."
      end
      puts "Appuyez sur Entrée pour continuer..."
      STDIN.gets
    end
  end
end
