# MatrixRB

## Overview
 MatrixRB is a Ruby-based MVC (Model-View-Controller) application designed to perform various matrix operations through a command-line interface. It supports operations such as addition, subtraction, multiplication, transposition, and inversion of matrices.

## Features
- Show famous matrix effect on terminal.
- Settings menu : Change color theme, matrix size, speed, etc.
- Config saving and loading using YAML.
- Update checker.
- Cross-Platform: Compatible with Windows, macOS, and Linux.

## Requirements
- Ruby 2.5 or higher
### Required Gems:
- io-console
- colorize
- yaml
- win32ole *(Windows only)*

## Installation
 1. Clone the repository: 

```git clone```

 2. Navigate to the project directory:

```cd MatrixRB```
 3. Install the required gems:

```gem install io-console colorize yaml```

```gem install win32ole``` *(Windows only)*
 4. Run the application:

```ruby main.rb```

## Usage
Follow the on-screen prompts to perform matrix operations. You can navigate through the menu to select different operations and settings.
## Configuration
Configuration settings are saved in config.yaml. You can modify this file to change default settings such as matrix size, color theme, and speed.
## Contributing
Contributions are welcome! Please fork the repository and create a pull request with your changes.
## License
This project is licensed under the CNL (CycloNetworks License). See the LICENSE(.en/.fr).md file for details.
## Contact
For support or inquiries, please open an issue on the GitHub repository or contact the maintainer at contact{at}cyclonetworks.com