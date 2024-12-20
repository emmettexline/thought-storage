#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Uninstalling thought-store...${NC}"

# Get the Neovim config directory
NVIM_CONFIG_DIR="${HOME}/.config/nvim"

# Remove the plugin files
echo "Removing plugin files..."
rm -rf "${NVIM_CONFIG_DIR}/lua/thought_store"
rm "${NVIM_CONFIG_DIR}/plugin/thought_store.vim"

# Remove references from init.lua
if [ -f "${NVIM_CONFIG_DIR}/init.lua" ]; then
    echo "Removing plugin configuration from init.lua..."
    sed -i '/-- Thought Store Plugin/,+1d' "${NVIM_CONFIG_DIR}/init.lua"
fi

# Remove storage directory
STORAGE_DIR="${NVIM_CONFIG_DIR}/thought_store"
if [ -d "$STORAGE_DIR" ]; then
    echo "Removing storage directory..."
    rm -rf "$STORAGE_DIR"
fi

echo -e "${GREEN}Uninstallation complete!${NC}"
