FROM mcr.microsoft.com/dotnet/sdk:9.0 AS base

RUN apt-get update && apt-get install -y \
    wget unzip libfreetype6 libgl1 libx11-6 libxcursor1 \
    libxinerama1 libxrandr2 libxi6 libasound2 libpulse0 \
    libudev1 libxext6 libxrender1 \
    libwayland-client0 libxkbcommon0 libwayland-cursor0 libwayland-egl1-mesa \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*

RUN wget -O godot.zip https://github.com/godotengine/godot/releases/download/4.4.1-stable/Godot_v4.4.1-stable_mono_linux_x86_64.zip \
    && unzip godot.zip -d /opt/godot

RUN ln -s /opt/godot/Godot_v4.4.1-stable_mono_linux_x86_64/Godot_v4.4.1-stable_mono_linux.x86_64 /usr/bin/godot

CMD ["godot", "--version"]