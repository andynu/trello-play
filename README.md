# Trello API Integration

This project provides tools to interact with the Trello API, available in both Ruby and Python implementations.

## Prerequisites

- Ruby 3.x (for Ruby version)
- Python 3.12 (for Python version)
- Trello API credentials (API Key and Secret)

## Environment Setup

1. Copy the `.env.example` file to `.env`:
   ```bash
   cp dotenv.example .env
   ```

2. Edit the `.env` file and add your Trello API credentials:
   - `TRELLO_API_KEY`: Your Trello API key
   - `TRELLO_SECRET`: Your Trello API secret

## Ruby Version Setup

1. Navigate to the Ruby directory:
   ```bash
   cd ruby
   ```

2. Make the initialization script executable and run it:
   ```bash
   chmod +x initialize_ruby.sh
   ./initialize_ruby.sh
   ```
   This script will:
   - Check if Ruby is installed
   - Check if Bundler is installed (and install it if needed)
   - Install all required dependencies

3. Run the Ruby version:
   ```bash
   ruby trello.rb
   ```

## Python Version Setup

1. Navigate to the Python directory:
   ```bash
   cd python
   ```

2. Make the initialization script executable and run it:
   ```bash
   chmod +x initialize_python.sh
   ./initialize_python.sh
   ```
   This script will:
   - Create a Python virtual environment
   - Activate the virtual environment
   - Install all required dependencies

3. Activate the virtual environment (required before running the script):
   ```bash
   source venv/bin/activate  # On Linux/Mac
   # or
   .\venv\Scripts\activate  # On Windows
   ```

4. Run the Python version:
   ```bash
   python trello.py
   ```

   Note: You'll need to activate the virtual environment each time you open a new terminal session.

## Features

Both implementations provide the same core functionality:
- Authentication with Trello API
- Board management
- List and card operations
- Member management

## Dependencies

### Ruby Version
- dotenv (~> 2.8)
- httparty (~> 0.21)
- json (~> 2.6)
- yaml (~> 0.2)

### Python Version
- python-dotenv (1.1.0)
- requests (2.32.3)
- pyyaml (6.0.2)
- certifi (2025.1.31)
- charset-normalizer (3.4.1)
- idna (3.10)
- urllib3 (2.4.0)

## Contributing

Feel free to submit issues and enhancement requests!

## License

This project is open source and available under the MIT License.
