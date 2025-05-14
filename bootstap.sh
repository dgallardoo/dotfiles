#!/bin/bash
# Minimal bootstrap script for bash environments.

set -e # Exit immediately if a command exits with a non-zero status.

echo "Starting dotfiles bootstrap process..."

# --- Helper function to check if a command exists ---
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# --- User-specific binary directory ---
USER_BIN_DIR="${HOME}/.local/bin"
mkdir --parents "${USER_BIN_DIR}"

# --- Install Starship (if not already installed) ---
if ! command_exists starship; then
    echo "Starship not found. Attempting to install to ${USER_BIN_DIR}..."
    if curl --silent --show-error https://starship.rs/install.sh | sh -s -- -y -b "${USER_BIN_DIR}"; then
        echo "Starship installed successfully to ${USER_BIN_DIR}."
    else
        echo "Starship installation failed. Please check output or try manually."
    fi
else
    echo "Starship already installed."
fi

# --- Ensure USER_BIN_DIR is in PATH for .bashrc ---
BASHRC_FILE="${HOME}/.bashrc"
PATH_EXPORT_CMD="export PATH=\"${USER_BIN_DIR}:\$PATH\""
PATH_COMMENT="# Add user's local bin to PATH (managed by dotfiles bootstrap)"

touch "${BASHRC_FILE}" # Ensure .bashrc exists

# The -- after options signifies the end of options, useful if PATH_EXPORT_CMD could start with '-'
if ! grep --quiet --fixed-strings -- "${PATH_EXPORT_CMD}" "${BASHRC_FILE}"; then
    echo "Adding ${USER_BIN_DIR} to PATH in ${BASHRC_FILE}."
    printf "\n%s\n%s\n" "${PATH_COMMENT}" "${PATH_EXPORT_CMD}" >> "$BASHRC_FILE"
else
    echo "${USER_BIN_DIR} already in PATH in ${BASHRC_FILE}."
fi

# --- Run the configuration linking script (install.sh) ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_SCRIPT_PATH="${SCRIPT_DIR}/install.sh"

if [ -f "${INSTALL_SCRIPT_PATH}" ]; then
    echo "Running configuration linking script: ${INSTALL_SCRIPT_PATH}..."
    sh "${INSTALL_SCRIPT_PATH}"
else
    echo "ERROR: ${INSTALL_SCRIPT_PATH} not found!"
    exit 1
fi

# --- Initialize Starship in .bashrc (if installed) ---
if command_exists starship; then
    STARSHIP_INIT_CMD='eval "$(starship init bash)"'
    STARSHIP_COMMENT="# Initialize Starship (managed by dotfiles bootstrap)"

    if ! grep --quiet --fixed-strings -- "${STARSHIP_INIT_CMD}" "${BASHRC_FILE}"; then
        echo "Adding Starship initialization to ${BASHRC_FILE}."
        printf "\n%s\n%s\n" "${STARSHIP_COMMENT}" "${STARSHIP_INIT_CMD}" >> "$BASHRC_FILE"
    else
        echo "Starship already initialized in ${BASHRC_FILE}."
    fi
else
    echo "Starship command not found after attempting installation. Skipping Starship init."
fi

echo "Dotfiles bootstrap process finished."
echo "Please source your ~/.bashrc (e.g., 'source ~/.bashrc') or open a new terminal for changes to take effect."
