# main.rb
# Entry point for MatrixRB MVC app
# Check Ruby version
ruby_version = RUBY_VERSION
if ruby_version < "2.5"
  puts "Ruby 2.5 or higher is required."
  exit(1)
end
# Check for required gems 
begin
  require 'io/console'
  require 'colorize'
  require 'yaml'
  require 'win32ole' if RUBY_PLATFORM =~ /mswin|mingw|cygwin/
rescue LoadError => e
  if RUBY_PLATFORM =~ /mswin|mingw|cygwin/ && e.message.include?('win32ole')
    puts "Required gem missing: #{e.message}. Please install the required gems by running 'gem install io-console colorize yaml win32ole'."
  else
    puts "Required gem missing: #{e.message}. Please install the required gems by running 'gem install io-console colorize yaml'."
  end
  exit(1)
end

# Check for MVC files
unless File.exist?('matrix_model.rb') && File.exist?('matrix_view.rb') && File.exist?('matrix_controller.rb')
  puts "One or more required files (matrix_model.rb, matrix_view.rb, matrix_controller.rb) are missing."
  exit(1)
end

require_relative 'matrix_model'
require_relative 'matrix_view'

require_relative 'matrix_controller'

MatrixController.new.run
