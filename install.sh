#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo -e "${BLUE}Installing thought-store...${NC}"

# Get the Neovim config directory
NVIM_CONFIG_DIR="${HOME}/.config/nvim"

# Create necessary directories
echo "Creating directories..."
mkdir -p "${NVIM_CONFIG_DIR}/lua/thought_store"
mkdir -p "${NVIM_CONFIG_DIR}/plugin"

# Copy lua files
echo "Copying plugin files..."
cp -r "${SCRIPT_DIR}/scripts/lua/thought_store/"* "${NVIM_CONFIG_DIR}/lua/thought_store/"
cp "${SCRIPT_DIR}/scripts/plugin/thought_store.vim" "${NVIM_CONFIG_DIR}/plugin/"

# Handle init.lua
if [ ! -f "${NVIM_CONFIG_DIR}/init.lua" ]; then
    echo "Creating init.lua..."
    echo -e "-- Thought Store Plugin\nrequire('thought_store').setup()" > "${NVIM_CONFIG_DIR}/init.lua"
else
    echo -e "${BLUE}Existing init.lua found${NC}"
    if ! grep -q "require('thought_store')" "${NVIM_CONFIG_DIR}/init.lua"; then
        echo "Adding plugin configuration..."
        echo -e "\n-- Thought Store Plugin\nrequire('thought_store').setup()" >> "${NVIM_CONFIG_DIR}/init.lua"
        echo "Configuration added to init.lua"
    else
        echo "Plugin already configured in init.lua"
    fi
fi

# Create storage directory
STORAGE_DIR="${NVIM_CONFIG_DIR}/thought_store"
if [ ! -d "$STORAGE_DIR" ]; then
    mkdir -p "$STORAGE_DIR"
    echo "Created storage directory at ${STORAGE_DIR}"
fi

# Verify Ollama installation
if ! command -v ollama &> /dev/null; then
    echo -e "${RED}Warning: Ollama is not installed${NC}"
    echo "Please install Ollama from https://ollama.ai"
    echo "Then run: ollama pull llama3.2"
fi

echo -e "${GREEN}Installation complete!${NC}"
echo -e "You can now use the following commands in Neovim:"
echo -e "${BLUE}:ST${NC} - Save thought"
echo -e "${BLUE}:B${NC}  - Browse thoughts"
echo -e "\nIn the browser:"
echo -e "${BLUE}<Enter>${NC} - View/edit thought"
echo -e "${BLUE}d${NC}      - Delete thought"
echo -e "${BLUE}q${NC}      - Quit browser"
echo -e "${BLUE}<leader>w${NC} - Save changes (when editing)"
