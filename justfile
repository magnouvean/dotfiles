default: hostname flatpak brew vscode gnome dotfiles services

services:
    systemctl --user enable syncthing
    systemctl --user start syncthing

hostname-suffix := `hostnamectl chassis`

hostname:
    hostnamectl hostname ublue-{{ hostname-suffix }}

flatpak:
    flatpak --user remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    ./scripts/flatpak_install

vscode:
    ./scripts/vscode_extensions_install

gnome:
    ./scripts/gnome_settings

dotfiles:
    if [ -f $HOME/.zshrc ]; then rm $HOME/.zshrc; fi
    if [ -f $HOME/.config/Code/User/settings.json ]; then rm $HOME/.config/Code/User/settings.json; fi
    stow -d files vscode -t $HOME
    stow -d files zsh -t $HOME

brew:
    ./scripts/brew_install