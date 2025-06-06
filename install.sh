#! /usr/bin/env bash

# ########################
# General helper functions
# ########################

# $1 - path
create_dir_if_dont_exist() {
    if [[ ! -e ${1} ]]; then
        echo "Creating ${1}"
        mkdir -p ${1}
    else
        echo "${1} exists"
    fi
}

# $1 - app name
print_ask_url_message() {
    echo "Please, enter the latest url for ${1}, "
    echo "or leave the field empty and I'll use what I have: "
}

# $1 - default url
ask_for_url() {
    read -r url
    if [[ -z ${url} ]]; then
        url=${1}
    fi

    echo ${url}
}

# ################
# Main directories
# ################
INSTALL_SCRIPT_DIR=$(realpath $(dirname ${0}))

TEMP_DIR="${HOME}/temp_dir"
DOWNLOADS_DIR="${TEMP_DIR}/downloads"

SSH_DIR="${HOME}/.ssh"

CONFIG_DIR="${HOME}/.config"
LOCAL_DIR="${HOME}/.local"
LOCAL_PACKAGES_DIR="${LOCAL_DIR}/packages"
LOCAL_BIN_DIR="${LOCAL_DIR}/bin"
LOCAL_DESKTOP_FILES_DIR="${LOCAL_DIR}/share/applications"

create_dir_if_dont_exist ${TEMP_DIR}
create_dir_if_dont_exist ${DOWNLOADS_DIR}

create_dir_if_dont_exist ${SSH_DIR}

create_dir_if_dont_exist ${CONFIG_DIR}
create_dir_if_dont_exist ${LOCAL_DIR}
create_dir_if_dont_exist ${LOCAL_PACKAGES_DIR}
create_dir_if_dont_exist ${LOCAL_BIN_DIR}
create_dir_if_dont_exist ${LOCAL_DESKTOP_FILES_DIR}

# ################################
# Install packages from repository
# ################################
install_apt_packages() {
    local basic_packages="vim zsh git curl wget tmux zip unzip  gcc make cmake bash-completion npm fzf xsel xclip ffmpeg 7zip jq poppler-utils zoxide imagemagick"
    local python_packages="python-is-python3 python3-all python3-venv python3-pip-whl python3-pip python3-pynvim"
    local gnome_packages="gnome-shell-extensions gnome-shell-extension-manager gnome-tweaks"
    local application_packages="synaptic dconf-editor vlc ubuntu-restricted-extras gimp libreoffice gtk-3-examples flameshot obs-studio"
    local additional_packages="flatpak"

    echo "Please, be ready to input your password. Press Enter now"
    read
    sudo apt install -y ${basic_packages} ${gnome_packages} ${python_packages} ${application_packages} ${additional_packages}
    # for pack in ${basic_packages} ${gnome_packages} ${python_packages} ${application_packages} ${additional_packages}; do
    #     sudo apt install ${pack}
    # done
}

# #########
# Setup git
# #########
setup_git() {
    echo -n "Do you want to install git ssh keys? [y/N]: "
    read -r ans
    
    if [[ "${ans}" == "y" ]]; then
        echo -n "Do you have existing git ssh keys? [y/N]: "
        read -r ans

        if [[ "${ans}" == "y" ]]; then
            echo "Put your existing git ssh keys into ${SSH_DIR}, run ssh-add for each key, and press Enter"
            read
        else
            echo -n "Enter your email: "
            read -r email

            echo "Generating keys"

            ssh-keygen -t ed25519 -C ${email}
            eval "$(ssh-agent -s)"
            ssh-add "${SSH_DIR}/id_ed25519"

            echo "Your public key:"
            cat "${SSH_DIR}/id_ed25519.pub"
            echo "Copy this, add to your github account, and press Enter"
            read
        fi

        git submodule update --init --recursive
    fi

}

# ################################################
# Functions to install packages from other sources
# ################################################
# $1 - url
download_package() {
    echo "Downloading ${1} to ${DOWNLOADS_DIR}"
    local filename=${1##*/}
    if [[ -e "${DOWNLOADS_DIR}/${filename}" ]]; then
        echo "${filename} exists, removing"
        rm "${DOWNLOADS_DIR}/${filename}"
    fi
    wget --show-progress -P ${DOWNLOADS_DIR} ${1}
}

# $1 - app name
# #2 - url
# $3 - ask for new url ["y" or empty]
install_deb_package() {
    printf "\n=> ${1}:\n"

    local url=${2}
    if [[ "${3}" == "y" ]]; then
        print_ask_url_message ${1}
        url=$(ask_for_url ${url})
    fi
    local package_name=${url##*/}
    local filepath="${DOWNLOADS_DIR}/${package_name}"

    download_package ${url}
    sudo dpkg -i ${filepath}
}

install_nvim() {
    printf "\n=> Nvim:\n"

    local url="https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.tar.gz"
    local package_name=${url##*/}
    local filepath="${DOWNLOADS_DIR}/${package_name}"
    local foldername=$(basename "${${filepath%.*}%.*}")

    download_package ${url}
    echo "Extracting ${filepath} to ${LOCAL_PACKAGES_DIR}"
    tar -C ${LOCAL_PACKAGES_DIR} -vxzf ${filepath}
    cd "${INSTALL_SCRIPT_DIR}"

    echo "Creating link to ${LOCAL_PACKAGES_DIR}/${foldername}/bin/nvim inside ${LOCAL_BIN_DIR}"
    ln -sf "${LOCAL_PACKAGES_DIR}/${foldername}/bin/nvim" "${LOCAL_BIN_DIR}/nvim"

    echo "Linking your local and remote configs"
    ln -sf "${INSTALL_SCRIPT_DIR}/nvim-config" "${CONFIG_DIR}/nvim"
}

install_oh_my_zsh() {
    printf "\n=> Oh my zsh:\n"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    mv "${HOME}/.zshrc" "${HOME}/.zshrc_bak"
    ln -sf "${INSTALL_SCRIPT_DIR}/zsh-config/.zshrc" "${HOME}/.zshrc"
    touch "${HOME}/.zshrc.ignore"
    ln -sf "${INSTALL_SCRIPT_DIR}/zsh-config/mylocal.zsh-theme" "${HOME}/.oh-my-zsh/themes"
}

# $1 - ask for new url ["y" or empty]
install_lazygit() {
    printf "\n=> Lazygit:\n"

    local url="https://github.com/jesseduffield/lazygit/releases/download/v0.51.1/lazygit_0.51.1_Linux_x86_64.tar.gz"
    if [[ "${1}" == "y" ]]; then
        print_ask_url_message "Lazygit"
        url=$(ask_for_url ${url})
    fi
    local package_name=${url##*/}
    local filepath="${DOWNLOADS_DIR}/${package_name}"

    download_package ${url}
    echo "Extracting ${filepath} to ${LOCAL_PACKAGES_DIR}"
    tar -C ${LOCAL_PACKAGES_DIR} -vxzf ${filepath} lazygit
    echo "Creating link inside ${LOCAL_BIN_DIR}"
    ln -sf "${LOCAL_PACKAGES_DIR}/lazygit" "${LOCAL_BIN_DIR}/lazygit"
}

install_kitty() {
    printf "\n=> Kitty:\n"

    echo "Running install scrip for kitty"
    curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin dest=${LOCAL_PACKAGES_DIR} launch=n
    ln -sf "${LOCAL_PACKAGES_DIR}/kitty.app/bin/kitty" "${LOCAL_PACKAGES_DIR}/kitty.app/bin/kitten" ${LOCAL_BIN_DIR}
    cp "${LOCAL_PACKAGES_DIR}/kitty.app/share/applications/kitty.desktop" ${LOCAL_DESKTOP_FILES_DIR}
    sed -i "s|Icon=kitty|Icon=${LOCAL_PACKAGES_DIR}/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|g" "${LOCAL_DESKTOP_FILES_DIR}/kitty.desktop"
    sed -i "s|Exec=kitty|Exec=${LOCAL_PACKAGES_DIR}/kitty.app/bin/kitty|g" "${LOCAL_DESKTOP_FILES_DIR}/kitty.desktop"

    echo "Setting theme for kitty"
    ln -sf "${INSTALL_SCRIPT_DIR}/kitty-config/kitty-themes/themes/Sundried.conf" "${INSTALL_SCRIPT_DIR}/kitty-config/theme.conf"

    echo "Linking your local and remote configs"
    ln -sf "${INSTALL_SCRIPT_DIR}/kitty-config" "${CONFIG_DIR}/kitty"
}

install_telegram() {
    printf "\n=> Telegram:\n"

    local url="https://telegram.org/dl/desktop/linux"
    local package_name="linux"
    local filepath="${DOWNLOADS_DIR}/${package_name}"

    download_package ${url}
    echo "Extracting ${filepath} to ${LOCAL_PACKAGES_DIR}"
    tar -C ${LOCAL_PACKAGES_DIR} -vxJf ${filepath}
    ${LOCAL_PACKAGES_DIR}/Telegram/Telegram
}

# $1 - ask for new url ["y" or empty]
install_vial() {
    printf "\n=> Vial:\n"

    local url="https://github.com/vial-kb/vial-gui/releases/download/v0.7.3/Vial-v0.7.3-x86_64.AppImage"
    if [[ "${1}" == "y" ]]; then
        print_ask_url_message "Vial"
        url=$(ask_for_url ${url})
    fi
    local package_name=${url##*/}
    local filepath="${DOWNLOADS_DIR}/${package_name}"

    download_package ${url}
    cp ${filepath} "${LOCAL_PACKAGES_DIR}/vial"
    chmod +x "${LOCAL_PACKAGES_DIR}/vial"

    echo "Creating .desktop file for vial"
    cp "${INSTALL_SCRIPT_DIR}/desktop_files/vial.desktop" "${LOCAL_DESKTOP_FILES_DIR}"

    echo "Setting udev rule"
    export USER_GID=`id -g`; sudo --preserve-env=USER_GID sh -c 'echo "KERNEL==\"hidraw*\", SUBSYSTEM==\"hidraw\", ATTRS{serial}==\"*vial:f64c2b3c*\", MODE=\"0660\", GROUP=\"$USER_GID\", TAG+=\"uaccess\", TAG+=\"udev-acl\"" > /etc/udev/rules.d/99-vial.rules && udevadm control --reload && udevadm trigger'
}

install_fzf() {
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install
}

install_rust() {
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
}

install_yazi() {
    cargo install --locked yazi-fm yazi-cli
}


# ###############################
# Functions to configure packages
# ###############################
configure_keybindings() {
    # == Caps as Ctrl ==
    gsettings set org.gnome.desktop.input-sources xkb-options "['ctrl:nocaps']"

    # == Workspaces ==
    for i in {1..9}; do
        gsettings set org.gnome.shell.keybindings switch-to-application-${i} "[]"
        gsettings set org.gnome.shell.keybindings open-new-window-application-${i} "[]"
        gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-${i} "['<Super>${i}']"
        gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-${i} "['<Super><Control>${i}']"
    done

    # == Windows ==
    gsettings set org.gnome.desktop.wm.keybindings switch-applications "[]"
    gsettings set org.gnome.desktop.wm.keybindings switch-applications-backward "[]"
    gsettings set org.gnome.desktop.wm.keybindings switch-windows "['<Alt>Tab', '<Super>Tab']"
    gsettings set org.gnome.desktop.wm.keybindings switch-windows-backward "['<Shift><Alt>Tab', '<Shift><Super>Tab']"
    gsettings set org.gnome.desktop.wm.keybindings show-desktop "[]"
    gsettings set org.gnome.desktop.wm.keybindings close "['<Super>c']"
    gsettings set org.gnome.desktop.wm.keybindings maximize "[]"
    gsettings set org.gnome.desktop.wm.keybindings unmaximize "[]"
    gsettings set org.gnome.desktop.wm.keybindings minimize "['<Super>m']"
    gsettings set org.gnome.desktop.wm.keybindings toggle-fullscreen "['<Shift><Super>f']"

    # == App starters
    gsettings set org.gnome.settings-daemon.plugins.media-keys home "['<Super>e']"
    gsettings set org.gnome.settings-daemon.plugins.media-keys www "['<Super>b']"

    gsettings set org.gnome.shell.keybindings show-screenshot-ui "[]"

    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/']"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'flameshot'
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 'flameshot gui'
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'Print'

    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'kitty'
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 'sh -c ~/.local/bin/kitty'
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name '<Super>Return'
}

configure_tmux() {
    printf "\n=> Tmux:\n"
    local tmux_dir="${CONFIG_DIR}/tmux"

    create_dir_if_dont_exist ${tmux_dir}
    echo "Linking your local and remote configs"
    ln -sf "${INSTALL_SCRIPT_DIR}/tmux-config/tmux.conf" "${tmux_dir}"
    git clone https://github.com/tmux-plugins/tpm "${tmux_dir}/plugins/tpm"
    echo "After tmux start press prefix+I to install plugins"
}

configure_flatpak() {
    printf "\n=> Flatpak:\n"
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
}

configure_corne() {
    printf "\n=> Corne:\n"

    local qmk_dir="${HOME}/Documents/qmk-fw"
    create_dir_if_dont_exist ${qmk_dir}

    cd ${qmk_dir}
    python -m venv venv
    source venv/bin/activate
    pip install qmk

    git clone https://github.com/vial-kb/vial-qmk.git
    cd vial-qmk
    qmk setup

    deactivate
    cd ${INSTALL_SCRIPT_DIR}

    ln -sf "${INSTALL_SCRIPT_DIR}/corne-fw" "${qmk_dir}/vial-qmk/keyboards/crkbd/keymaps/201dreamers"
}

# ###########
# Main script
# ###########
printf "\n====================\n"
echo "Hi, this is your local Jarvis, I'll help you to install the environment"
echo "Updating all packages"
echo "Please, be ready to input your password. Press Enter now"
read
sudo apt update && sudo apt upgrade -y

printf "\n====================\n"
echo "Installing packages from repository"
install_apt_packages

printf "\n====================\n"
echo "Setting up Git"
setup_git

printf "\n====================\n"
echo "Installing packages from other sources"
echo -n "Do you want to provide urls for new versions of packages? [y/N]: "
read -r ans
install_deb_package "Ripgrep" "https://github.com/BurntSushi/ripgrep/releases/download/14.1.1/ripgrep_14.1.1-1_amd64.deb" ${ans}
install_deb_package "Fd" "https://github.com/sharkdp/fd/releases/download/v10.2.0/fd_10.2.0_amd64.deb" ${ans}

install_lazygit ${ans}
install_vial ${ans}

install_deb_package "Chrome" "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"

install_rust
install_nvim
install_oh_my_zsh
install_kitty
install_yazi

printf "\n====================\n"
echo -n "Do you want to install Telegram Desktop? [y/N]: "
read -r ans
if [[ "${ans}" == "y" ]]; then
    install_telegram
fi

printf "\n====================\n"
echo "Configuring system & packages"
configure_keybindings
configure_tmux
configure_flatpak
echo -n "Do you want to configure corne? [y/N]: "
read -r ans
if [[ "${ans}" == "y" ]]; then
    configure_corne
fi

printf "\n====================\n"
echo -n "Do you want to turn off Ubuntu reporting? [y/N]: "
read -r ans
if [[ "${ans}" == "y" ]]; then
    sudo ubuntu-report -f send no
fi

echo -n "You need to reboot the system. Do you want to do it now? [y/N]: "
read -r ans
if [[ "${ans}" == "y" ]]; then
    reboot
fi

rm -rf ${TEMP_DIR}
