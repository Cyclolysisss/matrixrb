if $0 == __FILE__
  warn "This file is intended to be used as part of the MatrixRB program and should not be run directly. please run 'ruby main.rb' instead."
  exit 1
end

# matrix_controller.rb
# Controller: Handles user input, program flow, and coordination between model and view

require_relative 'matrix_model'
require_relative 'matrix_view'
require 'io/console'

class MatrixController
  VERSION = '1.1.1'
  CREATOR = 'Cyclolysis'
  PROGRAM_NAME = 'MatrixRB'

  def initialize
    @model = MatrixModel.new
    # Try to auto-load config file if it exists, else use defaults
    if File.exist?('matrix_config.yml')
      loaded = @model.load_config('matrix_config.yml', VERSION)
      unless loaded
        puts "Failed to load configuration from matrix_config.yml. Using default settings."
      end
    end
    @view = MatrixView.new
    @stop = false
    @start_time = nil
    @version_check_result = nil
    begin
      require 'open-uri'
      latest_version = URI.open('https://raw.githubusercontent.com/Cyclolysisss/MatrixRB/main/VERSION').read.strip
      if latest_version != VERSION
        @version_check_result = "New version available: #{latest_version} (you are using version v#{VERSION}). Visit https://github.com/Cyclolysisss/MatrixRB (or run 'git pull' if you have used 'git clone') for more information and to update."
      end
    rescue
      
    end
  end

  def run
    # Show intro and version check result (if any) together
    @view.display_intro(VERSION, CREATOR, PROGRAM_NAME, @version_check_result)
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
          require 'rbconfig'
          os_type = RbConfig::CONFIG['host_os']
          os_version = RUBY_PLATFORM
          os_friendly = case os_type
            when /mswin|mingw|cygwin/ then "Microsoft Windows"
            when /darwin/ then "Apple macOS"
            when /linux/ then "GNU/Linux"
            else os_type
          end
          os_full_version = begin
            if os_friendly == "Microsoft Windows"
              require 'win32ole'
              wmi = WIN32OLE.connect("winmgmts://")
              os = wmi.ExecQuery("select * from Win32_OperatingSystem").each.first
              "#{os.Caption} (Build #{os.BuildNumber})"
            elsif os_friendly == "Apple macOS"
              `sw_vers -productVersion`.strip
            elsif os_friendly == "GNU/Linux"
              if File.exist?('/etc/os-release')
                File.read('/etc/os-release')[/PRETTY_NAME="([^"]+)"/, 1] || 'Linux'
              else
                'Linux'
              end
            else
              os_version
            end
          rescue
            os_version
          end
          sys_seconds = begin
            if os_friendly == "Microsoft Windows"
              require 'win32ole'
              wmi = WIN32OLE.connect("winmgmts://")
              os = wmi.ExecQuery("select * from Win32_OperatingSystem").each.first
              last_boot = os.LastBootUpTime
              boot_time = Time.new(last_boot[0..3], last_boot[4..5], last_boot[6..7], last_boot[8..9], last_boot[10..11], last_boot[12..13])
              (Time.now - boot_time).to_i
            elsif os_friendly == "Apple macOS" || os_friendly == "GNU/Linux"
              if File.exist?('/proc/uptime')
                IO.read('/proc/uptime').split[0].to_i
              elsif os_friendly == "Apple macOS"
                # Use sysctl for boot time on macOS
                boot = `sysctl -n kern.boottime 2>/dev/null`.strip
                if boot =~ /sec = (\d+)/
                  boot_time = Time.at($1.to_i)
                  (Time.now - boot_time).to_i
                else
                  0
                end
              else
                0
              end
            else
              0
            end
          rescue
            0
          end
          def format_uptime(total)
            years = total / (365*24*3600)
            total %= (365*24*3600)
            months = total / (30*24*3600)
            total %= (30*24*3600)
            weeks = total / (7*24*3600)
            total %= (7*24*3600)
            days = total / (24*3600)
            total %= (24*3600)
            hours = total / 3600
            total %= 3600
            mins = total / 60
            secs = total % 60
            "#{years}y #{months}mo #{weeks}w #{days}d %02d:%02d:%02d" % [hours, mins, secs]
          end
          prog_seconds = (Time.now - @start_time).to_i
          puts "[DEBUG] Terminal size: cols=#{@model.columns}, rows=#{@model.rows}"
          puts "[DEBUG] First row: #{@model.character_matrix[0].inspect}"
          puts "[DEBUG] OS: #{os_friendly}"
          puts "[DEBUG] OS version: #{os_full_version}"
          puts "[DEBUG] System uptime: #{format_uptime(sys_seconds)}"
          puts "[DEBUG] Program uptime: #{format_uptime(prog_seconds)}"
          puts "[DEBUG] Current menu: main loop"
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
        current_menu = 'save config menu'
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
        current_menu = 'load config menu'
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
        current_menu = 'set speed menu'
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
        current_menu = 'set bold probability menu'
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
        current_menu = 'set fade probability menu'
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
        current_menu = 'set duration menu'
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
        current_menu = 'toggle bold menu'
        @model.bold_enabled = !@model.bold_enabled
        puts "Bold effect #{@model.bold_enabled ? 'enabled' : 'disabled'}."
      when 'g'
        current_menu = 'toggle fade menu'
        @model.fade_enabled = !@model.fade_enabled
        puts "Fade effect #{@model.fade_enabled ? 'enabled' : 'disabled'}."
      when 'v'
        current_menu = 'toggle speed variation menu'
        @model.speed_variation_enabled = !@model.speed_variation_enabled
        puts "Speed variation #{@model.speed_variation_enabled ? 'enabled' : 'disabled'}."
      when 'n'
        current_menu = 'toggle random bold menu'
        @model.random_bold_enabled = !@model.random_bold_enabled
        puts "Random bold effect #{@model.random_bold_enabled ? 'enabled' : 'disabled'}."
      when 'm'
        current_menu = 'toggle random fade menu'
        @model.random_fade_enabled = !@model.random_fade_enabled
        puts "Random fade effect #{@model.random_fade_enabled ? 'enabled' : 'disabled'}."
      when 'h'
        current_menu = 'help menu'
        @view.display_help(@model)
      when 'u'
        current_menu = 'update check menu'
        puts "\nChecking for updates..."
        begin
          require 'open-uri'
          latest_version = URI.open('https://raw.githubusercontent.com/Cyclolysisss/MatrixRB/main/VERSION').read.strip
          if latest_version != VERSION
            puts "New version available: #{latest_version} (you are using version v#{VERSION})."
            puts "Visit https://github.com/Cyclolysisss/MatrixRB for more information and to update (an Internet connection is required)."
            puts "Or run 'git pull' if you installed via 'git clone' (Still requires an Internet connection)."
          else
            puts "You are using the latest version (v#{VERSION})."
          end
        rescue => e
          puts "Failed to check for updates: #{e.message}"
        end
      when 'x'
        current_menu = 'reset menu'
        # Reset to defaults
        @model = MatrixModel.new
        puts "Settings reset."
      else
        current_menu = 'unknown menu'
        puts "Unknown command. Type 'h' for help."
      end
      puts "Press Enter to continue..."
      STDIN.gets
    end
  end
end
