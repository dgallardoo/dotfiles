#!/bin/bash
# Minimal bootstrap script for bash environments.

set -e # Exit immediately if a command exits with a non-zero status.

echo "Starting dotfiles bootstrap process..."

# --- Helper function to check if a command exists ---
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# --- Shell detection ---
detect_shell() {
    # First check $SHELL environment variable
    local DETECTED_SHELL
    DETECTED_SHELL=$(basename "$SHELL" 2>/dev/null || echo "")

    # If $SHELL is empty or doesn't exist, try to get from /etc/passwd
    if [ -z "$DETECTED_SHELL" ] && [ -r "/etc/passwd" ]; then
        DETECTED_SHELL=$(grep "^$USER:" /etc/passwd | cut -d: -f7 | xargs basename 2>/dev/null || echo "")
    fi

    # If shell is still empty after checks, it remains empty.
    # The calling code will handle cases where CURRENT_SHELL is not in SUPPORTED_SHELLS.
    echo "$DETECTED_SHELL"
}

# --- Determine current shell ---
CURRENT_SHELL=$(detect_shell)
echo "Detected shell: $CURRENT_SHELL"

# --- Supported shells ---
SUPPORTED_SHELLS="bash zsh"

is_shell_supported() {
    local shell_to_check="$1"
    for supported_shell in $SUPPORTED_SHELLS; do
        if [ "$supported_shell" = "$shell_to_check" ]; then
            return 0 # Supported
        fi
    done
    return 1 # Not supported
}

# --- User-specific binary directory ---
USER_BIN_DIR="${HOME}/.local/bin"
mkdir --parents "${USER_BIN_DIR}"

# --- Generic function to add lines to config files if they don't exist ---
add_to_file_if_missing() {
    local FILE_PATH="$1"
    local LINE_CONTENT="$2"
    local COMMENT="$3"

    touch "$FILE_PATH" # Ensure file exists

    # The -- after options signifies the end of options, useful if LINE_CONTENT could start with '-'
    if ! grep --quiet --fixed-strings --line-regexp -- "$LINE_CONTENT" "$FILE_PATH"; then
        echo "Adding to $FILE_PATH: $LINE_CONTENT"
        printf "\n%s\n%s\n" "$COMMENT" "$LINE_CONTENT" >> "$FILE_PATH"
        return 0 # Added
    else
        # echo "Content already exists in $FILE_PATH: $LINE_CONTENT"
        return 1 # Not added (already exists)
    fi
}

# --- Tool Configuration ---
# This function will handle the configuration for a given tool and shell.
configure_tool_for_shell() {
    local tool_name="$1"
    local shell_name="$2"
    local rc_file=""
    local init_cmd=""
    local comment=""
    local configured=false

    echo "Configuring $tool_name for $shell_name..."

    case "$tool_name" in
        starship)
            if ! command_exists starship; then
                echo "Starship command not found. Attempting to install to ${USER_BIN_DIR}..."
                if curl --silent --show-error https://starship.rs/install.sh | sh -s -- --yes --bin-dir "${USER_BIN_DIR}"; then
                    echo "Starship installed successfully to ${USER_BIN_DIR}."
                else
                    echo "Starship installation failed. Please check output or try manually. Skipping $tool_name configuration."
                    return 1
                fi
            else
                echo "Starship already installed."
            fi

            comment="# Initialize Starship prompt (managed by dotfiles bootstrap)"
            case "$shell_name" in
                bash)
                    rc_file="${HOME}/.bashrc"
                    init_cmd='eval "$(starship init bash)"'
                    configured=true
                    ;;
                zsh)
                    rc_file="${HOME}/.zshrc"
                    init_cmd='eval "$(starship init zsh)"'
                    configured=true
                    ;;
                *)
                    # This case should ideally not be reached if pre-checked by is_shell_supported
                    echo "Warning: $tool_name does not support shell $shell_name."
                    return 1
                    ;;
            esac
            ;;
        *)
            echo "Warning: Configuration for tool '$tool_name' is not defined."
            return 1
            ;;
    esac

    if [ "$configured" = true ] && [ -n "$rc_file" ] && [ -n "$init_cmd" ]; then
        if add_to_file_if_missing "$rc_file" "$init_cmd" "$comment"; then
            echo "$tool_name initialized for $shell_name in $rc_file."
        else
            echo "$tool_name already initialized for $shell_name in $rc_file."
        fi
    elif [ "$configured" = false ]; then
        # This condition might be redundant if the inner case handles unsupported shells for the tool
        echo "Warning: $tool_name configuration skipped for $shell_name (not supported by tool or shell)."
    fi
    return 0
}


# --- Main Configuration Logic ---

# 1. Ensure USER_BIN_DIR is in PATH
if is_shell_supported "$CURRENT_SHELL"; then
    PATH_EXPORT_CMD="export PATH=\"${USER_BIN_DIR}:\$PATH\""
    PATH_COMMENT="# Add user's local bin to PATH (managed by dotfiles bootstrap)"
    RC_FILE=""

    case "$CURRENT_SHELL" in
        bash)
            RC_FILE="${HOME}/.bashrc"
            ;;
        zsh)
            RC_FILE="${HOME}/.zshrc"
            ;;
    esac

    if [ -n "$RC_FILE" ]; then
        touch "${RC_FILE}" # Ensure RC file exists
        if add_to_file_if_missing "$RC_FILE" "$PATH_EXPORT_CMD" "$PATH_COMMENT"; then
            echo "Added ${USER_BIN_DIR} to PATH in ${RC_FILE}."
        else
            echo "${USER_BIN_DIR} already in PATH in ${RC_FILE}."
        fi
    fi
else
    echo "Warning: Current shell '$CURRENT_SHELL' is not supported for PATH configuration. Supported shells: $SUPPORTED_SHELLS."
    echo "Please add ${USER_BIN_DIR} to your PATH manually if needed."
fi


# 2. Run the configuration linking script (install.sh)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_SCRIPT_PATH="${SCRIPT_DIR}/install.sh"

if [ -f "${INSTALL_SCRIPT_PATH}" ]; then
    echo "Running configuration linking script: ${INSTALL_SCRIPT_PATH}..."
    sh "${INSTALL_SCRIPT_PATH}"
else
    echo "ERROR: ${INSTALL_SCRIPT_PATH} not found!"
fi


# 3. Configure tools
TOOLS_TO_CONFIGURE="starship" # Add other tools here, space-separated, e.g., "starship another_tool"

if is_shell_supported "$CURRENT_SHELL"; then
    echo "Proceeding with tool configurations for $CURRENT_SHELL."
    for tool in $TOOLS_TO_CONFIGURE; do
        configure_tool_for_shell "$tool" "$CURRENT_SHELL"
    done

    # Suggest sourcing the RC file
    RC_TO_SOURCE=""
    case "$CURRENT_SHELL" in
        bash) RC_TO_SOURCE="${HOME}/.bashrc" ;;
        zsh)  RC_TO_SOURCE="${HOME}/.zshrc" ;;
    esac
    if [ -n "$RC_TO_SOURCE" ]; then
        echo "Please run 'source $RC_TO_SOURCE' or open a new terminal for all changes to take effect."
    fi
else
    echo "Warning: Current shell '$CURRENT_SHELL' is not supported. Supported shells: $SUPPORTED_SHELLS."
    echo "Skipping tool configurations. To configure manually, please refer to individual tool documentation."
    echo "Starship manual install: https://starship.rs/installing/"
fi

echo "Dotfiles bootstrap process finished."
