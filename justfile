default:
    just -f {{justfile()}} --list

sync: hostname flatpak brew vscode gnome dotfiles services groups

[private]
services:
    systemctl --user enable syncthing
    systemctl --user start syncthing

[private]
hostname-suffix := `hostnamectl chassis`

[private]
hostname:
    hostnamectl hostname ublue-{{ hostname-suffix }}

[private]
flatpak:
    flatpak --user remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    {{justfile_directory()}}/scripts/flatpak_install

[private]
vscode:
    {{justfile_directory()}}/scripts/vscode_extensions_install

[private]
gnome:
    {{justfile_directory()}}/scripts/gnome_settings

[private]
groups:
    if ! groups $USER | grep -q docker; then \
        sudo usermod -aG docker $USER; \
    fi

[private]
dotfiles:
    if [ -f $HOME/.zshrc ]; then rm $HOME/.zshrc; fi
    if [ -f $HOME/.config/Code/User/settings.json ]; then rm $HOME/.config/Code/User/settings.json; fi
    if [ -f $HOME/.continue/config.json ]; then rm $HOME/.continue/config.json; fi
    if [ -f $HOME/.config/containers/containers.conf ]; then rm $HOME/.config/containers/containers.conf; fi
    stow -d files vscode -t $HOME
    stow -d files podman -t $HOME

    cp files/zsh/.zshrc $HOME/.zshrc
    printf "\nalias ujust=\"just -f {{justfile()}}\"" >> $HOME/.zshrc

[private]
brew:
    {{justfile_directory()}}/scripts/brew_install

devcontainer name:
    mkdir -p {{invocation_directory()}}/.devcontainers/
    cp {{justfile_directory()}}/files/devcontainers/{{name}}.json {{invocation_directory()}}/.devcontainers/devcontainer.json