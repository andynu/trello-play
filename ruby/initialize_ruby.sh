#!/bin/bash
set -e

# Check if Ruby is installed
if ! command -v ruby &> /dev/null; then
    echo "Error: Ruby is not installed. Please install Ruby before proceeding."
    echo "You can install Ruby using rbenv, rvm, or your system's package manager."
    exit 1
fi

# Check if Bundler is installed
if ! command -v bundle &> /dev/null; then
    echo "Bundler is not installed. Attempting to install..."
    gem install bundler
    if [ $? -ne 0 ]; then
        echo "Failed to install Bundler. Please install it manually using: gem install bundler"
        exit 1
    fi
fi

# Install dependencies
bundle install
