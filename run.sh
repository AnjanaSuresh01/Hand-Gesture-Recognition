#!/bin/bash

# Exit on any error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print with color
print_status() {
    echo -e "${BLUE}[*]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[+]${NC} $1"
}

print_error() {
    echo -e "${RED}[-]${NC} $1"
}

# Check if python3 is installed
if ! command -v python3 &> /dev/null; then
    print_error "Python3 is not installed. Please install Python3 first."
    exit 1
fi

# Define virtual environment name
VENV_NAME="hand_tracking_env"

# Create virtual environment if it doesn't exist
if [ ! -d "$VENV_NAME" ]; then
    print_status "Creating virtual environment '$VENV_NAME'..."
    python3 -m venv "$VENV_NAME"
else
    print_status "Virtual environment '$VENV_NAME' already exists."
fi

# Activate the virtual environment
print_status "Activating virtual environment..."
source "$VENV_NAME/bin/activate"

# Verify virtual environment is activated
if [[ "$VIRTUAL_ENV" != *"$VENV_NAME"* ]]; then
    print_error "Failed to activate virtual environment."
    exit 1
fi

print_success "Virtual environment activated successfully!"

# Upgrade pip and install dependencies
print_status "Installing required packages..."
pip install --upgrade pip
pip install opencv-python mediapipe numpy pynput

print_success "Dependencies installed successfully!"

# Check if the Python script exists
SCRIPT_NAME="robotarmtrack.py"
if [ ! -f "$SCRIPT_NAME" ]; then
    print_error "$SCRIPT_NAME not found in the current directory!"
    deactivate
    exit 1
fi

# Run the Python script
print_status "Running $SCRIPT_NAME..."
python "$SCRIPT_NAME"

# Deactivate virtual environment after script execution
deactivate
print_success "Script execution completed!"

