default:
    just -f {{justfile()}} --list

sync: hostname flatpak brew vscode gnome dotfiles zed-extensions-remove services groups podman-pull

[private]
services:
    systemctl --user enable syncthing
    systemctl --user start syncthing
    systemctl --user enable ollama
    systemctl --user start ollama

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
    stow -d files vscode -t $HOME
    if [ -d $HOME/.config/systemd/user ]; then rm -rf $HOME/.config/systemd/user; fi
    mkdir -p $HOME/.config/systemd
    cp -r files/systemd/.config/systemd/user $HOME/.config/systemd/user
    if [ -f $HOME/.var/app/dev.zed.Zed/config/zed/settings.json ]; then rm $HOME/.var/app/dev.zed.Zed/config/zed/settings.json; fi
    mkdir -p $HOME/.var/app/dev.zed.Zed/config/zed
    stow -d files zed -t $HOME/.var/app/dev.zed.Zed/config/zed

    cp files/zsh/.zshrc $HOME/.zshrc
    printf "\nalias ujust=\"just -f {{justfile()}}\"" >> $HOME/.zshrc

[private]
brew:
    {{justfile_directory()}}/scripts/brew_install

[private]
podman-pull:
    podman pull ollama/ollama:latest
    podman image prune

[private]
zed-extensions-remove:
    #!/usr/bin/env python
    import json
    import os
    import shutil

    with open("{{justfile_directory()}}/files/zed/settings.json", "r") as file:
        zed_config = json.load(file)
    extensions = zed_config["auto_install_extensions"].keys()
    installed_extensions_dir = os.path.expanduser(f"~/.var/app/dev.zed.Zed/data/zed/extensions/installed")
    for installed_extension in os.listdir(installed_extensions_dir):
        if installed_extension not in extensions:
            print(extensions, installed_extension, installed_extension in extensions)
            print(f"Removing zed extension: {installed_extension}")
            shutil.rmtree(f"{installed_extensions_dir}/{installed_extension}")

devcontainer name port:
    #!/bin/bash
    export CONTAINER_ID="{{name}}_$(echo {{invocation_directory()}} | md5sum | cut -c1-8)"
    extra_args=$(envsubst < {{justfile_directory()}}/devcontainers/{{name}}/extra_args)
    podman build {{justfile_directory()}}/devcontainers/{{name}} -t $CONTAINER_ID
    echo "podman run -it --gpus=all --security-opt label=disable -d --replace -p {{port}}:22 -v zed-server:/root/.zed_server -v "{{invocation_directory()}}:/workspace" --name $CONTAINER_ID $CONTAINER_ID $extra_args"
    podman run -it --gpus=all --security-opt label=disable -d --replace -p {{port}}:22 -v zed-server:/root/.zed_server -v "{{invocation_directory()}}:/workspace"  $extra_args --name $CONTAINER_ID $CONTAINER_ID
    podman exec $CONTAINER_ID service ssh start
