#!/bin/bash

# Colors for fancy output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
log_info() {
    echo -e "${GREEN}[i]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[w]${NC} $1"
}

log_err() {
    echo -e "${RED}[e]${NC} $1"
}

# Function to check if AVX2 is supported
check_avx2_support() {
    if grep -q avx2 /proc/cpuinfo; then
        return 0  # AVX2 supported
    else
        return 1  # AVX2 not supported
    fi
}

# Show kawaii ASCII art
show_welcome_art() {
    log_info "╔════════════════════════════════════════════════════╗"
    log_info "║                                                    ║"
    log_info "║    (ﾉ◕ヮ◕)ﾉ*:･ﾟ✧  Zen Browser Tarball Installer   ║"
    log_info "║                                                    ║"
    
    if check_avx2_support; then
        log_info "║    CPU: AVX2 Supported (Optimized Version)         ║"
    else
        log_info "║    CPU: AVX2 Not Supported (Generic Version)       ║"
    fi

    log_info "║                                                    ║"
    log_info "╚════════════════════════════════════════════════════╝"
    log_info ""
}

# Main installation menu
main_menu() {
    show_welcome_art

    log_info "(★^O^★) Which version of Zen Browser would you like to install?"
    log_info "  1) Stable Version"
    log_info "  2) Twilight Version"
    log_info "  0) Exit"
    read -p "Enter your choice (0-2): " main_choice

    case $main_choice in
        1)
            install_zen_browser 0
            ;;
        2)
            install_zen_browser 1
            ;;
        0)
            log_info "(⌒‿⌒) Exiting..."
            exit 0
            ;;
        *)
            log_err "(•ˋ _ ˊ•) Invalid choice. Exiting..."
            exit 1
            ;;
    esac
}

# Installation function
install_zen_browser() {
    local is_twilight="$1"
    local official_package_location

    # URLs for both stable and Twilight versions
    local official_package_location_generic_stable="https://github.com/zen-browser/desktop/releases/latest/download/zen.linux-generic.tar.bz2"
    local official_package_location_specific_stable="https://github.com/zen-browser/desktop/releases/latest/download/zen.linux-specific.tar.bz2"
    local official_package_location_generic_twilight="https://github.com/zen-browser/desktop/releases/download/twilight/zen.linux-generic.tar.bz2"
    local official_package_location_specific_twilight="https://github.com/zen-browser/desktop/releases/download/twilight/zen.linux-specific.tar.bz2"

    # Select appropriate package based on Twilight mode and AVX2 support
    if [[ "$is_twilight" == 1 ]]; then
        if check_avx2_support; then
            official_package_location="$official_package_location_specific_twilight"
            log_warn "Installing Zen Browser Twilight (Optimized Version)"
        else
            official_package_location="$official_package_location_generic_twilight"
            log_warn "Installing Zen Browser Twilight (Generic Version)"
        fi
    else
        if check_avx2_support; then
            official_package_location="$official_package_location_specific_stable"
            log_warn "Installing Zen Browser Stable (Optimized Version)"
        else
            official_package_location="$official_package_location_generic_stable"
            log_warn "Installing Zen Browser Stable (Generic Version)"
        fi
    fi

    local app_name=zen
    local literal_name_of_installation_directory=".tarball-installations"
    local universal_path_for_installation_directory="$HOME/$literal_name_of_installation_directory"
    local app_installation_directory="$universal_path_for_installation_directory/zen"
    local tar_location=$(mktemp /tmp/zen.XXXXXX.tar.bz2)
    local open_tar_application_data_location="zen"
    local local_bin_path="$HOME/.local/bin"
    local local_application_path="$HOME/.local/share/applications"
    local app_bin_in_local_bin="$local_bin_path/$app_name"
    local desktop_in_local_applications="$local_application_path/$app_name.desktop"
    local icon_path="$app_installation_directory/browser/chrome/icons/default/default128.png"
    local executable_path=$app_installation_directory/zen

    log_info "Zen Browser installation started!"

    sleep 1

    log_info "Checking for and removing existing installations..."
    if [ -f "$app_bin_in_local_bin" ]; then
        log_warn "Old bin file detected, removing..."
        rm "$app_bin_in_local_bin"
    fi

    if [ -d "$app_installation_directory" ]; then
        log_warn "Old app files found, removing..."
        rm -rf "$app_installation_directory"
    fi

    if [ -f "$desktop_in_local_applications" ]; then
        log_warn "Old desktop file found, removing..."
        rm "$desktop_in_local_applications"
    fi

    log_info "Downloading the package..."
    curl -L -o $tar_location $official_package_location
    if [ $? -eq 0 ]; then
        log_info "Download successful!"
    else
        log_err "Installation failed. Curl not found or not installed"
        exit 1
    fi

    tar -xvjf $tar_location

    log_info "Creating installation directories..."
    if [ ! -d $universal_path_for_installation_directory ]; then
        mkdir $universal_path_for_installation_directory
    fi

    mv $open_tar_application_data_location $app_installation_directory

    rm $tar_location

    if [ ! -d $local_bin_path ]; then
        log_info "Creating $local_bin_path"
        mkdir $local_bin_path
    fi

    touch $app_bin_in_local_bin
    chmod u+x $app_bin_in_local_bin
    echo "#!/bin/bash
$executable_path" >> $app_bin_in_local_bin

    if [ ! -d $local_application_path ]; then
        log_info "Creating $local_application_path"
        mkdir $local_application_path
    fi

    touch $desktop_in_local_applications
    echo "
[Desktop Entry]
Name=Zen
Keywords=web;browser;internet
Exec=$executable_path %u
Icon=$icon_path
Terminal=false
Type=Application
MimeType=text/html;text/xml;application/xhtml+xml;application/vnd.mozilla.xul+xml;text/mml;x-scheme-handler/http;x-scheme-handler/https;
Categories=Network;WebBrowser;
Actions=new-window;new-private-window;profile-manager-window;
[Desktop Action new-window]
Name=Open a New Window
Exec=$executable_path --new-window %u
[Desktop Action new-private-window]
Name=Open a New Private Window
Exec=$executable_path --private-window %u
[Desktop Action profile-manager-window]
Name=Open the Profile Manager
Exec=$executable_path --ProfileManager
" >> $desktop_in_local_applications

    log_info "(｡♥‿♥｡) Installation successful!"
    log_info "Zen Browser is now installed. Have fun! 🐷"
}

# Create necessary directories
mkdir -p ~/.local/share/applications
mkdir -p ~/.local/bin
mkdir -p ~/.tarball-installations

# Execute the main menu
main_menu
