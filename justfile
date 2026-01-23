default:
    just -f {{justfile()}} --list

# Should be run most of the time
sync: hostname flatpak vscode gnome

[private]
hostname-suffix := `hostnamectl chassis`

[private]
hostname:
    hostnamectl hostname bluefin-{{ hostname-suffix }}

[private]
flatpak:
    #!/bin/sh
    for flatpak in $(flatpak list --system --columns=ref); do flatpak remove --system -y --noninteractive $flatpak; done
    flatpak --user remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    {{justfile_directory()}}/scripts/flatpak_install

[private]
vscode:
    {{justfile_directory()}}/scripts/vscode_extensions_install

[private]
gnome:
    {{justfile_directory()}}/scripts/gnome_settings
