#!/bin/sh
set -e # Exit immediately if a command exits with a non-zero status.

echo "Running dotfiles install script..."

# The script runs from the root of the cloned dotfiles repository.
DOTFILES_ROOT_DIR=$(pwd)
TARGET_LOCAL_CONFIG_DIR="${HOME}/.config"

mkdir -p "${TARGET_LOCAL_CONFIG_DIR}" # Ensure the target directory exists

SOURCE_STARSHIP_CONFIG_FILE="${DOTFILES_ROOT_DIR}/.config/starship.toml"
TARGET_STARSHIP_CONFIG_FILE="${TARGET_LOCAL_CONFIG_DIR}/starship.toml"
echo "Linking starship configuration..."
# Create the symlink, -f to force overwrite if it exists, -s for symbolic
ln -sf "${SOURCE_STARSHIP_CONFIG_FILE}" "${TARGET_STARSHIP_CONFIG_FILE}"

SOURCE_GITCONFIG_FILE="${DOTFILES_ROOT_DIR}/.gitconfig"
TARGET_GITCONFIG_FILE="${HOME}/.gitconfig"
echo "Linking .gitconfig..."
ln -sf "${SOURCE_GITCONFIG_FILE}" "${TARGET_GITCONFIG_FILE}"

echo "Dotfiles install script finished."
