default:
    just -f {{justfile()}} --list

# Should be run initially on first install, or when adding new system packages in general
sync-full: packages packages-update sync # shell hostname flatpak vscode gnome dotfiles zed-extensions-remove services
sync-full-nvidia: packages packages-nvidia packages-update sync # shell hostname flatpak vscode gnome dotfiles zed-extensions-remove services

# Should be run most of the time
sync: shell hostname flatpak vscode gnome dotfiles zed-extensions-remove services systemfiles

[private]
packages:
    sudo rpm-ostree reset
    rpm-ostree install -y \
        bat \
        jetbrains-mono-fonts \
        just \
        ripgrep \
        syncthing \
        vim \
        zsh \
        zsh-autosuggestions \
        zsh-syntax-highlighting

[private]
packages-nvidia:
    #!/bin/bash
    rpm-ostree install \
        https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

    rpm-ostree install akmod-nvidia xorg-x11-drv-nvidia xorg-x11-drv-nvidia-cuda
    rpm-ostree kargs --append=modprobe.blacklist=nova_core --append=modprobe.blacklist=nouveau --append=nvidia-drm.modeset=1
    rpm-ostree initramfs --enable

    # Container toolkit
    curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | \
        sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo
    NVIDIA_CONTAINER_TOOLKIT_VERSION=1.17.8-1
    rpm-ostree install -y \
        nvidia-container-toolkit-${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
        nvidia-container-toolkit-base-${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
        libnvidia-container-tools-${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
        libnvidia-container1-${NVIDIA_CONTAINER_TOOLKIT_VERSION}

[private]
packages-update:
    rpm-ostree update

[private]
shell:
    if ! [ "$SHELL" = "/usr/bin/zsh" ]; then chsh -s /usr/bin/zsh $USER; fi

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
    hostnamectl hostname silverblue-{{ hostname-suffix }}

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
dotfiles:
    # VSCodium
    if [ -f $HOME/.var/app/com.vscodium.codium/config/VSCodium/User/settings.json ]; then rm $HOME/.var/app/com.vscodium.codium/config/VSCodium/User/settings.json; fi
    mkdir -p $HOME/.var/app/com.vscodium.codium/config/VSCodium/User
    ln -s {{justfile_directory()}}/files/vscodium/settings.json $HOME/.var/app/com.vscodium.codium/config/VSCodium/User/settings.json

    # Systemd
    if [ -d $HOME/.config/systemd/user ]; then rm -rf $HOME/.config/systemd/user; fi
    mkdir -p $HOME/.config/systemd/user
    cp {{justfile_directory()}}/files/systemd/ollama.service $HOME/.config/systemd/user/ollama.service

    # Zed
    if [ -f $HOME/.var/app/dev.zed.Zed/config/zed/settings.json ]; then rm $HOME/.var/app/dev.zed.Zed/config/zed/settings.json; fi
    mkdir -p $HOME/.var/app/dev.zed.Zed/config/zed
    cp {{justfile_directory()}}/files/zed/settings.json $HOME/.var/app/dev.zed.Zed/config/zed/settings.json

    # ZSH
    if [ -f $HOME/.zshrc ]; then rm $HOME/.zshrc; fi
    cp {{justfile_directory()}}/files/zsh/.zshrc $HOME/.zshrc
    printf "\nalias ujust=\"just -f {{justfile()}}\"" >> $HOME/.zshrc

[private]
systemfiles:
    if ! [ -f /etc/cdi/nvidia.yaml ] && command -v nvidia-ctk; then \
        sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml; \
    fi

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
    if os.path.exists(installed_extensions_dir):
        for installed_extension in os.listdir(installed_extensions_dir):
            if installed_extension not in extensions:
                print(extensions, installed_extension, installed_extension in extensions)
                print(f"Removing zed extension: {installed_extension}")
                shutil.rmtree(f"{installed_extensions_dir}/{installed_extension}")

devcontainer name port:
    #!/bin/bash
    if [ -d {{invocation_directory()}}/{{name}} ]; then \
        export CONTAINER_SOURCE="{{invocation_directory()}}/{{name}}"; \
    else \
        export CONTAINER_SOURCE="{{justfile_directory()}}/devcontainers/{{name}}"; \
    fi
    export CONTAINER_ID="$(basename {{invocation_directory()}})_$(echo {{invocation_directory()}} | md5sum | cut -c1-8)"
    extra_args=$(envsubst < $CONTAINER_SOURCE/extra_args)
    echo "podman build $CONTAINER_SOURCE -t $CONTAINER_ID"
    podman build $CONTAINER_SOURCE -t $CONTAINER_ID
    podman run -it --gpus=all --security-opt label=disable -d --replace -p {{port}}:22 -v vscodium-server_$CONTAINER_ID:/root/.vscodium-server -v zed-server:/root/.zed_server -v "{{invocation_directory()}}:/workspace"  $extra_args --name $CONTAINER_ID $CONTAINER_ID
    podman exec $CONTAINER_ID service ssh start
    if [ -f $HOME/.ssh/known_hosts ]; then rm $HOME/.ssh/known_hosts; fi

podman-pull:
    podman pull ollama/ollama:latest
    podman image prune
