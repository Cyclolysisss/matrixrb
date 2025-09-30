# matrixeffect.rb
# A matrix effect simulation in the terminal using Ruby (with green characters). and some other cool features like fading and bold characters. and more features like random bold characters, fading effect, and speed variation, then letting the user customize the effect..
# When first launched, show the creator name and version number caracter by character for 3 seconds, then clear the screen and start the matrix effect.

require 'io/console'
require 'thread'
require 'securerandom'
begin
  require 'colorize'
rescue LoadError
  puts "La gem 'colorize' est requise. Installez-la avec : gem install colorize"
  exit 1
end
require 'rbconfig'
require 'open3'
require 'rbconfig' 
require 'fileutils'
require 'tempfile'
require 'time'
require 'digest'
require 'net/http'
require 'uri'
require 'json'

# Constants
VERSION = '1.0.0'
CREATOR = 'Cyclolysis'
DEFAULT_SPEED = 0.1
DEFAULT_BOLD_PROBABILITY = 0.1
DEFAULT_FADE_PROBABILITY = 0.05
CHARACTER_SET = (' '..'~').to_a + (' '..'~').to_a.map(&:upcase) # Printable ASCII characters
CLEAR_COMMAND = RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/ ? 'cls' : 'clear'
MATRIX_COLOR = :green
BOLD_COLOR = :light_green
FADE_COLOR = :dark_green
RESET_COLOR = :default
MIN_SPEED = 0.01
MAX_SPEED = 1.0
MIN_BOLD_PROBABILITY = 0.0
MAX_BOLD_PROBABILITY = 1.0
MIN_FADE_PROBABILITY = 0.0
MAX_FADE_PROBABILITY = 1.0
DEFAULT_COLUMNS = 80
DEFAULT_ROWS = 24
MIN_COLUMNS = 20
MAX_COLUMNS = 200
MIN_ROWS = 10
MAX_ROWS = 100
DEFAULT_DURATION = nil # infinite
MIN_DURATION = 1
MAX_DURATION = nil # infinite
DEFAULT_BOLD_ENABLED = true
DEFAULT_FADE_ENABLED = true
DEFAULT_SPEED_VARIATION_ENABLED = true
DEFAULT_RANDOM_BOLD_ENABLED = true
DEFAULT_RANDOM_FADE_ENABLED = true


# Global Variables
$stop = false
$mutex = Mutex.new
$columns = DEFAULT_COLUMNS
$rows = DEFAULT_ROWS
$speed = DEFAULT_SPEED
$bold_probability = DEFAULT_BOLD_PROBABILITY
$fade_probability = DEFAULT_FADE_PROBABILITY
$duration = DEFAULT_DURATION
$bold_enabled = DEFAULT_BOLD_ENABLED
$fade_enabled = DEFAULT_FADE_ENABLED
$speed_variation_enabled = DEFAULT_SPEED_VARIATION_ENABLED
$random_bold_enabled = DEFAULT_RANDOM_BOLD_ENABLED
$random_fade_enabled = DEFAULT_RANDOM_FADE_ENABLED
$start_time = nil
$threads = []
$character_matrix = []
$fade_matrix = []
$bold_matrix = []
$original_columns = nil
$original_rows = nil
$original_speed = nil
$original_bold_probability = nil
$original_fade_probability = nil
$original_duration = nil
$original_bold_enabled = nil
$original_fade_enabled = nil
$original_speed_variation_enabled = nil
$original_random_bold_enabled = nil
$original_random_fade_enabled = nil
$version_check_thread = nil
$latest_version = VERSION
$update_available = false
$update_url = 'https://github.com/Cyclolysis/matrixeffect/releases/latest'
$config_file = File.join(Dir.home, '.matrixeffect_config.json')
$log_file = File.join(Dir.home, '.matrixeffect_log.txt')
$debug_mode = false
$log_mutex = Mutex.new

# Function to log messages to a file
def log_message(message)
  return unless $debug_mode
  $log_mutex.synchronize do
    File.open($log_file, 'a') do |file|
      file.puts("[#{Time.now}] #{message}")
    end
  end
rescue => e
  puts "Logging error: #{e.message}"
end
# Function to load configuration from file
def load_config
  return unless File.exist?($config_file)
  config = JSON.parse(File.read($config_file))
  $columns = config['columns'] if config['columns']
  $rows = config['rows'] if config['rows']
  $speed = config['speed'] if config['speed']
  $bold_probability = config['bold_probability'] if config['bold_probability']
  $fade_probability = config['fade_probability'] if config['fade_probability']
  $duration = config['duration'] if config['duration']
  $bold_enabled = config['bold_enabled'] unless config['bold_enabled'].nil?
  $fade_enabled = config['fade_enabled'] unless config['fade_enabled'].nil?
  $speed_variation_enabled = config['speed_variation_enabled'] unless config['speed_variation_enabled'].nil?
  $random_bold_enabled = config['random_bold_enabled'] unless config['random_bold_enabled'].nil?
  $random_fade_enabled = config['random_fade_enabled'] unless config['random_fade_enabled'].nil?
rescue => e
  log_message("Error loading config: #{e.message}")
end
# Function to save configuration to file
def save_config
  config = {
    'columns' => $columns,
    'rows' => $rows,
    'speed' => $speed,
    'bold_probability' => $bold_probability,
    'fade_probability' => $fade_probability,
    'duration' => $duration,
    'bold_enabled' => $bold_enabled,
    'fade_enabled' => $fade_enabled,
    'speed_variation_enabled' => $speed_variation_enabled,
    'random_bold_enabled' => $random_bold_enabled,
    'random_fade_enabled' => $random_fade_enabled
  }
  File.open($config_file, 'w') do |file|
    file.write(JSON.pretty_generate(config))
  end
rescue => e
  log_message("Error saving config: #{e.message}")
end
# Function to check for updates
def check_for_updates
  Thread.new do
    begin
      uri = URI('https://api.github.com/repos/Cyclolysis/matrixeffect/releases/latest')
      response = Net::HTTP.get(uri)
      data = JSON.parse(response)
      latest_version = data['tag_name']
      if Gem::Version.new(latest_version) > Gem::Version.new(VERSION)
        $latest_version = latest_version
        $update_available = true
        $update_url = data['html_url'] || $update_url
      end
    rescue => e
      log_message("Error checking for updates: #{e.message}")
    end
  end
end
# Function to clear the terminal screen
def clear_screen
  system(CLEAR_COMMAND)
rescue => e
  log_message("Error clearing screen: #{e.message}")
end
# Function to display the creator name and version number character by character
def display_intro
  clear_screen
  intro_text = "Matrix Effect v#{VERSION} by #{CREATOR}, press 'o' for options"
  intro_text.each_char do |char|
    print char.colorize(MATRIX_COLOR)
    sleep(0.1)
  end
  sleep(3)
  clear_screen
rescue => e
  log_message("Error displaying intro: #{e.message}")
end
# Function to initialize the character matrix
def initialize_matrices
  $character_matrix = Array.new($rows) { Array.new($columns) { CHARACTER_SET.sample } }
  $fade_matrix = Array.new($rows) { Array.new($columns, 0) }
  $bold_matrix = Array.new($rows) { Array.new($columns, false) }
rescue => e
  log_message("Error initializing matrices: #{e.message}")
end
# Function to update the character matrix
def update_matrices
  $rows.times do |row|
    $columns.times do |col|
      if rand < 0.1
        $character_matrix[row][col] = CHARACTER_SET.sample
      end
      if $fade_enabled && rand < $fade_probability
        $fade_matrix[row][col] = [$fade_matrix[row][col] + 1, 3].min
      else
        $fade_matrix[row][col] = [$fade_matrix[row][col] - 1, 0].max
      end
      if $bold_enabled && rand < $bold_probability
        $bold_matrix[row][col] = true
      elsif $random_bold_enabled && rand < 0.05
        $bold_matrix[row][col] = !$bold_matrix[row][col]
      end
    end
  end
rescue => e
  log_message("Error updating matrices: #{e.message}")
end
# Function to render the character matrix to the terminal
def render_matrices
  clear_screen
  output = ""
  $rows.times do |row|
    $columns.times do |col|
      char = $character_matrix[row][col]
      if $fade_enabled && $fade_matrix[row][col] > 0
        color = case $fade_matrix[row][col]
                when 1 then FADE_COLOR
                when 2 then :light_black
                when 3 then :black
                else MATRIX_COLOR
                end
      else
        color = MATRIX_COLOR
      end
      if $bold_enabled && $bold_matrix[row][col]
        output << char.colorize(color).bold
      else
        output << char.colorize(color)
      end
    end
    output << "\n"
  end
  print output
rescue => e
  log_message("Error rendering matrices: #{e.message}")
end

def safe_getch
  STDIN.getch
rescue => e
  log_message("Error reading character: #{e.message}")
  nil
end

# Function to handle user input
def handle_user_input
  Thread.new do
    loop do
      char = safe_getch
      $mutex.synchronize do
        if char == 'o'
          $pause_matrix = true
        elsif char == 'q'
          $stop = true
        end
      end
      break if $stop
    end
  end
rescue => e
  log_message("Error handling user input: #{e.message}")
end
# Function to display help
def display_help
  puts <<-HELP

Matrix Effect Controls:
  q - Quit the program
  s - Set speed (#{MIN_SPEED}-#{MAX_SPEED}, current: #{$speed})
  b - Set bold probability (#{MIN_BOLD_PROBABILITY}-#{MAX_BOLD_PROBABILITY}, current: #{$bold_probability})
  f - Set fade probability (#{MIN_FADE_PROBABILITY}-#{MAX_FADE_PROBABILITY}, current: #{$fade_probability})
  d - Set duration in seconds (#{MIN_DURATION}-#{MAX_DURATION || 'infinite'}, current: #{$duration || 'infinite'})
  c - Set number of columns (#{MIN_COLUMNS}-#{MAX_COLUMNS}, current: #{$columns})
  r - Set number of rows (#{MIN_ROWS}-#{MAX_ROWS}, current: #{$rows})
  t - Toggle bold effect (#{$bold_enabled ? 'enabled' : 'disabled'})
  g - Toggle fade effect (#{$fade_enabled ? 'enabled' : 'disabled'})
  v - Toggle speed variation (#{$speed_variation_enabled ? 'enabled' : 'disabled'})
  n - Toggle random bold effect (#{$random_bold_enabled ? 'enabled' : 'disabled'})
  m - Toggle random fade effect (#{$random_fade_enabled ? 'enabled' : 'disabled'})
  h - Display this help message
  u - Check for updates
  x - Reset settings to original values

Press the corresponding key to execute the command.

HELP
rescue => e
  log_message("Error displaying help: #{e.message}")
end
# Main function
def main
  load_config
  $original_columns = $columns
  $original_rows = $rows
  $original_speed = $speed
  $original_bold_probability = $bold_probability
  $original_fade_probability = $fade_probability
  $original_duration = $duration
  $original_bold_enabled = $bold_enabled
  $original_fade_enabled = $fade_enabled
  $original_speed_variation_enabled = $speed_variation_enabled
  $original_random_bold_enabled = $random_bold_enabled
  $original_random_fade_enabled = $random_fade_enabled
  $pause_matrix = false
  display_intro
  initialize_matrices
  handle_user_input
  check_for_updates
  $start_time = Time.now
  loop do
    break if $stop
    if $pause_matrix
      show_options_menu
      $pause_matrix = false
      next
    end
    if $duration && (Time.now - $start_time) >= $duration
      puts "\nDuration reached. Exiting..."
      break
    end
    update_matrices
    render_matrices
    sleep_time = if $speed_variation_enabled
                   rand($speed * 0.5..$speed * 1.5)
                 else
                   $speed
                 end
    sleep(sleep_time)
  end
  clear_screen
  puts "Matrix Effect terminated. Goodbye!"
rescue => e
  log_message("Error in main function: #{e.message}")
end

# Affiche le menu d'options et gère les entrées utilisateur
def show_options_menu
  loop do
    clear_screen
    display_help
    puts "\nEntrez une commande (ou appuyez sur Entrée pour revenir à la matrice) :"
    print "> "
    input = STDIN.gets&.chomp
    break if input.nil? || input.empty?
    case input
    when 'q'
      $stop = true
      break
    when 's'
      print "\nNouvelle vitesse (#{MIN_SPEED}-#{MAX_SPEED}, actuel: #{$speed}): "
      val = STDIN.gets&.chomp
      if val =~ /^\d*\.?\d+$/
        new_speed = val.to_f
        if new_speed >= MIN_SPEED && new_speed <= MAX_SPEED
          $speed = new_speed
          puts "Vitesse mise à jour: #{$speed}"
        else
          puts "Valeur hors limites."
        end
      else
        puts "Entrée invalide."
      end
    when 'b'
      print "\nNouvelle probabilité bold (#{MIN_BOLD_PROBABILITY}-#{MAX_BOLD_PROBABILITY}, actuel: #{$bold_probability}): "
      val = STDIN.gets&.chomp
      if val =~ /^\d*\.?\d+$/
        new_bold = val.to_f
        if new_bold >= MIN_BOLD_PROBABILITY && new_bold <= MAX_BOLD_PROBABILITY
          $bold_probability = new_bold
          puts "Probabilité bold mise à jour: #{$bold_probability}"
        else
          puts "Valeur hors limites."
        end
      else
        puts "Entrée invalide."
      end
    when 'f'
      print "\nNouvelle probabilité fade (#{MIN_FADE_PROBABILITY}-#{MAX_FADE_PROBABILITY}, actuel: #{$fade_probability}): "
      val = STDIN.gets&.chomp
      if val =~ /^\d*\.?\d+$/
        new_fade = val.to_f
        if new_fade >= MIN_FADE_PROBABILITY && new_fade <= MAX_FADE_PROBABILITY
          $fade_probability = new_fade
          puts "Probabilité fade mise à jour: #{$fade_probability}"
        else
          puts "Valeur hors limites."
        end
      else
        puts "Entrée invalide."
      end
    when 'd'
      print "\nNouvelle durée en secondes (#{MIN_DURATION}-#{MAX_DURATION || 'infinite'}, actuel: #{$duration || 'infinite'}): "
      val = STDIN.gets&.chomp
      if val =~ /^\d*\.?\d+$/
        new_dur = val.to_f
        if new_dur >= MIN_DURATION && (MAX_DURATION.nil? || new_dur <= MAX_DURATION)
          $duration = new_dur
          puts "Durée mise à jour: #{$duration}"
        else
          puts "Valeur hors limites."
        end
      else
        puts "Entrée invalide."
      end
    when 'c'
      print "\nNouvelles colonnes (#{MIN_COLUMNS}-#{MAX_COLUMNS}, actuel: #{$columns}): "
      val = STDIN.gets&.chomp
      if val =~ /^\d+$/
        new_col = val.to_i
        if new_col >= MIN_COLUMNS && new_col <= MAX_COLUMNS
          $columns = new_col
          initialize_matrices
          puts "Colonnes mises à jour: #{$columns}"
        else
          puts "Valeur hors limites."
        end
      else
        puts "Entrée invalide."
      end
    when 'r'
      print "\nNouvelles lignes (#{MIN_ROWS}-#{MAX_ROWS}, actuel: #{$rows}): "
      val = STDIN.gets&.chomp
      if val =~ /^\d+$/
        new_row = val.to_i
        if new_row >= MIN_ROWS && new_row <= MAX_ROWS
          $rows = new_row
          initialize_matrices
          puts "Lignes mises à jour: #{$rows}"
        else
          puts "Valeur hors limites."
        end
      else
        puts "Entrée invalide."
      end
    when 't'
      $bold_enabled = !$bold_enabled
      puts "Effet bold #{$bold_enabled ? 'activé' : 'désactivé'}."
    when 'g'
      $fade_enabled = !$fade_enabled
      puts "Effet fade #{$fade_enabled ? 'activé' : 'désactivé'}."
    when 'v'
      $speed_variation_enabled = !$speed_variation_enabled
      puts "Variation vitesse #{$speed_variation_enabled ? 'activée' : 'désactivée'}."
    when 'n'
      $random_bold_enabled = !$random_bold_enabled
      puts "Effet bold aléatoire #{$random_bold_enabled ? 'activé' : 'désactivé'}."
    when 'm'
      $random_fade_enabled = !$random_fade_enabled
      puts "Effet fade aléatoire #{$random_fade_enabled ? 'activé' : 'désactivé'}."
    when 'h'
      display_help
    when 'u'
      if $update_available
        puts "Mise à jour disponible: #{$latest_version}. Rendez-vous sur #{$update_url}"
      else
        puts "Aucune mise à jour disponible."
      end
    when 'x'
      $columns = $original_columns
      $rows = $original_rows
      $speed = $original_speed
      $bold_probability = $original_bold_probability
      $fade_probability = $original_fade_probability
      $duration = $original_duration
      $bold_enabled = $original_bold_enabled
      $fade_enabled = $original_fade_enabled
      $speed_variation_enabled = $original_speed_variation_enabled
      $random_bold_enabled = $original_random_bold_enabled
      $random_fade_enabled = $original_random_fade_enabled
      initialize_matrices
      puts "Paramètres réinitialisés."
    else
      puts "Commande inconnue. Tapez 'h' pour l'aide."
    end
    save_config
    puts "Appuyez sur Entrée pour continuer..."
    STDIN.gets
  end
end
# Start the program
if __FILE__ == $0
  begin
    if STDIN.respond_to?(:raw)
      STDIN.raw do
        main
      end
    else
      # Fallback for environments without IO#raw (e.g., some Windows setups)
      main
    end
  rescue Exception => e
    log_message("Fatal error: #{e.message}\n#{e.backtrace.join("\n")}")
    puts "Une erreur fatale est survenue : #{e.message}"
  end
end
