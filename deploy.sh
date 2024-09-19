#!/usr/bin/env bash

set -euo pipefail

# Config
CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/remote_deploy.conf"
RCLONE="/usr/bin/rclone"
SCRIPT_NAME=$(basename "$0")
if [[ "$SCRIPT_NAME" == "bash" ]]; then
    SCRIPT_NAME="deploy"
fi
SCRIPT_URL="https://raw.githubusercontent.com/philiporange/deploy/refs/heads/main/deploy.sh"
INSTALL_DIR="/usr/local/bin"

# Utility functions
die() { echo "Error: $*" >&2; exit 1; }
info() { echo "Info: $*" >&2; }
confirm() { read -rp "$1 (y/N) " response && [[ $response =~ ^[Yy]$ ]]; }

# Display help
show_help() {
    cat << EOF
Usage: $SCRIPT_NAME <command> [options]

Commands:
  init                 Initialize or update configuration
  package <directory>  Package and upload a directory
  deploy <URL>         Deploy a package
  install              Install or update this script
  help                 Show this help message

For piped deployment:
  curl -sSL <SCRIPT_URL> | bash -s deploy <URL>
EOF
}

# Load config
load_config() {
    [[ -f $CONFIG_FILE ]] || die "Configuration file not found. Run '$SCRIPT_NAME init' first."
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
}

# Save config
save_config() {
    mkdir -p "$(dirname "$CONFIG_FILE")"
    cat > "$CONFIG_FILE" << EOF
BUCKET="$BUCKET"
BUCKET_URL="$BUCKET_URL"
RCLONE_DESTINATION="$RCLONE_DESTINATION"
RCLONE="$RCLONE"
SCRIPT_URL="$SCRIPT_URL"
EOF
    chmod 600 "$CONFIG_FILE"
    info "Configuration saved to $CONFIG_FILE"
}

# Initialize config
init_config() {
    info "Initializing configuration..."
    read -rp "Enter Backblaze B2 Bucket Name: " BUCKET
    read -rp "Enter Backblaze B2 Bucket URL: " BUCKET_URL
    read -rp "Enter rclone destination: " RCLONE_DESTINATION
    read -rp "Enter deploy script URL [$SCRIPT_URL]: " SCRIPT_URL_INPUT
    SCRIPT_URL=${SCRIPT_URL_INPUT:-$SCRIPT_URL}
    read -rp "Enter rclone path [$RCLONE]: " RCLONE_INPUT
    RCLONE=${RCLONE_INPUT:-$RCLONE}
    save_config
}

# Package directory
package_directory() {
    local dir=$1 name password tmp_dir ciphertext_file
    [[ -d $dir ]] || die "Directory '$dir' does not exist."

    name=$(basename "$(realpath "$dir")")
    tmp_dir=$(mktemp -d)

    cp -rL "$dir"/. "$tmp_dir/" || die "Failed to copy files."
    rm -rf "$tmp_dir/env"

    tar czf "/tmp/$name.tar.gz" -C "$tmp_dir" . || die "Failed to create archive."

    password=$(openssl rand -base64 16)
    ciphertext_file="/tmp/$name.tar.gz.enc"

    echo "$password" | openssl aes-256-cbc -salt -in "/tmp/$name.tar.gz" -out "$ciphertext_file" -pbkdf2 -iter 100000 -pass stdin || die "Encryption failed."

    info "Uploading package '$name'..."
    "$RCLONE" copyto "$ciphertext_file" "$RCLONE_DESTINATION/$name" > /dev/null 2>&1 || die "Upload failed."

    info "Deploy with: curl -sSL \"$SCRIPT_URL\" | bash -s deploy \"$BUCKET_URL/$name\" \"$password\""
}

# Deploy package
deploy_package() {
    local url=$1 password=$2 name ciphertext_file decrypted_file decompressed_dir

    name=$(basename "$url")
    ciphertext_file="$name.enc"
    decrypted_file="$name.tar.gz"
    decompressed_dir="$name"

    info "Deploying '$name' from '$url'..."

    rm -f "$ciphertext_file" "$decrypted_file"
    rm -rf "$decompressed_dir"

    curl -sSLf -o "$ciphertext_file" "$url" || die "Download failed."
    echo "$password" | openssl aes-256-cbc -d -salt -in "$ciphertext_file" -out "$decrypted_file" -pbkdf2 -iter 100000 -pass stdin || die "Decryption failed."

    mkdir -p "$decompressed_dir"
    tar xzf "$decrypted_file" -C "$decompressed_dir" || die "Decompression failed."

    rm -f "$ciphertext_file" "$decrypted_file"

    if [[ -f "$decompressed_dir/entrypoint.sh" ]]; then
        info "WARNING: About to execute '$decompressed_dir/entrypoint.sh'. Ensure you trust the source."
        if confirm "Do you want to continue?"; then
            (cd "$decompressed_dir" && bash "entrypoint.sh") || die "Failed to execute 'entrypoint.sh'."
        else
            die "Deployment aborted by user."
        fi
    fi

    info "Deployment completed successfully."
}

# Install script
install_script() {
    tmp_file=$(mktemp)

    info "Downloading latest version of the script..."
    if ! curl -sSLf -o "$tmp_file" "$SCRIPT_URL"; then
        die "Failed to download the script from $SCRIPT_URL"
    fi

    if [[ ! -d $INSTALL_DIR ]]; then
        sudo mkdir -p "$INSTALL_DIR" || die "Failed to create install directory $INSTALL_DIR"
    fi

    if ! sudo install -m 755 "$tmp_file" "$INSTALL_DIR/$SCRIPT_NAME"; then
        die "Failed to install the script to $INSTALL_DIR/$SCRIPT_NAME"
    fi

    info "Script installed successfully to $INSTALL_DIR/$SCRIPT_NAME"
}

# Main logic
case "${1-}" in
    init)   init_config ;;
    package)
        [[ $# -eq 2 ]] || die "Usage: $SCRIPT_NAME package <directory>"
        load_config
        package_directory "$2"
        ;;
    deploy)
        [[ $# -eq 3 ]] || die "Usage: $SCRIPT_NAME deploy <URL> <PASSWORD>"
        deploy_package "$2" "$3"
        ;;
    install)
        install_script
        ;;
    help|--help|-h) show_help ;;
    *) die "Unknown or missing command. Use '$SCRIPT_NAME help' for usage information." ;;
esac
