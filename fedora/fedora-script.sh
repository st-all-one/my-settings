#!/bin/sh
set -e

clear

echo "== Otimizando DNF5 =="
sudo tee /etc/dnf/dnf.conf << EOF
[main]
gpgcheck=True
installonly_limit=3
clean_requirements_on_remove=True
best=True
skip_if_unavailable=False
max_parallel_downloads=10
fastestmirror=True
metadata_expire=12h
EOF

echo "== Atualização de DNS =="
sudo mkdir -p '/etc/systemd/resolved.conf.d'
sudo tee /etc/systemd/resolved.conf.d/99-dns-over-tls.conf << EOF
[Resolve]
DNS=1.1.1.2#security.cloudflare-dns.com 1.0.0.2#security.cloudflare-dns.com 2606:4700:4700::1112#security.cloudflare-dns.com 2606:4700:4700::1002#security.cloudflare-dns.com
DNSOverTLS=yes
Domains=~.
EOF

echo "== Otimizações de performance =="
sudo tee /etc/sysctl.d/99-performance.conf << EOF
# Internet
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr

# Reduzir uso do NVME, priorizar RAM
vm.swappiness=1
vm.vfs_cache_pressure = 10
vm.dirty_expire_centisecs = 6000
vm.dirty_writeback_centisecs = 6000

# Otimizar processador
kernel.sched_min_granularity_ns = 10000000
kernel.sched_wakeup_granularity_ns = 15000000
kernel.sched_migration_cost_ns = 5000000

# MGLRU Para memoria
kernel.numa_balancing=0
EOF

sudo sysctl --system

sudo tee /etc/NetworkManager/conf.d/default-wifi-powersave-on.conf << EOF
[connection]
wifi.powersave = 2
EOF

sudo systemctl enable --now irqbalance

sudo systemctl disable NetworkManager-wait-online.service
sudo systemctl disable cups.service
sudo systemctl disable avahi-daemon.service
sudo systemctl disable akmods.service

echo "== Adicionando RPM Fusion non-free e terra =="
sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
sudo dnf install -y --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release

echo "== Atualização básica =="
sudo dnf group upgrade core -y
sudo dnf4 group install core -y
sudo dnf upgrade -y

echo "== Atualização de drivers e firmware =="
sudo fwupdmgr refresh --force
sudo fwupdmgr get-devices
sudo fwupdmgr get-updates
sudo fwupdmgr update -y

echo "== Flatpak =="
flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

echo "== Instação de codecs =="
sudo dnf4 group install multimedia -y
sudo dnf swap 'ffmpeg-free' 'ffmpeg' --allowerasing -y
sudo dnf update @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin -y
sudo dnf group install -y sound-and-video
sudo dnf install -y ffmpeg-libs libva libva-utils

echo "== Intalação de drivers =="
sudo dnf install -y mesa-va-drivers-freeworld
sudo dnf install -y mesa-va-drivers-freeworld.i686
sudo dnf install -y openh264 gstreamer1-plugin-openh264 mozilla-openh264
sudo dnf config-manager setopt fedora-cisco-openh264.enabled=1

echo "== Otimizações de zram =="
sudo tee /etc/systemd/zram-generator.conf << EOF
[zram0]
# Define o tamanho da ZRAM.
zram-size = 10240
# Algoritmo de compressão.
compression-algorithm = zstd
# Prioridade do swap (ZRAM deve ser sempre maior que o swap no disco)
swap-priority = 100
EOF

sudo systemctl daemon-reload
sudo systemctl start /dev/zram0

echo "== Instalações diversas =="
sudo dnf install -y zsh zsh-autosuggestions zsh-syntax-highlighting \
eza obs-studio chromium zoxide git-delta difftastic trash-cli fzf bat fd-find tldr

flatpak install flathub org.gimp.GIMP \
com.dec05eba.gpu_screen_recorder \
com.github.wwmm.pulseeffects \
de.haeckerfelix.Fragments \
org.gnome.Extensions \
com.mattermost.Desktop \
com.usebruno.Bruno -y

curl -f https://zed.dev/install.sh | sh

# Oh My ZSH
sudo chsh $USER --shell /usr/bin/zsh

# Docker
curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh
sudo usermod -aG docker $USER
sudo systemctl enable docker.service
sudo systemctl enable containerd.service
sudo systemctl enable --now docker

# NodeJS
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
\. "$HOME/.nvm/nvm.sh"
nvm install 25

# Google Gemini
npm install --no-audit -g @google/gemini-cli

echo "== Limpeza pós-install =="
sudo dnf autoremove -y
sudo dnf clean all -y

echo "== Otimizando Docker para Btrfs e Durabilidade do SSD =="
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json << EOF
{
  "storage-driver": "btrfs",
  "features": {
    "buildkit": true
  },
  "log-driver": "local",
  "log-opts": {
    "max-size": "10m",
    "compress": "true"
  }
}
EOF
sudo systemctl restart docker

echo "== Configurações =="
curl -fLo ~/.gitconfig https://raw.githubusercontent.com/st-all-one/my-settings/main/fedora/.gitconfig
curl -fLo ~/.zshrc https://raw.githubusercontent.com/st-all-one/my-settings/main/fedora/.zshrc
curl -fLo ~/.zsh-theme https://raw.githubusercontent.com/st-all-one/my-settings/main/fedora/.zsh-theme

# Instalando fonte Lilex Nerd Font
mkdir -p ~/.local/share/fonts/lilex && \
curl -L https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/Lilex.zip -o /tmp/lilex.zip && \
unzip -o /tmp/lilex.zip -d ~/.local/share/fonts/lilex && \
fc-cache -f && \
gsettings set org.gnome.Ptyxis font-name 'Lilex Nerd Font 11' && \
gsettings set org.gnome.Ptyxis use-system-font false && \
rm /tmp/lilex.zip

echo "== Instalações manuais =="
echo ""
echo "curl -fsSL https://deno.land/install.sh | sh"
echo "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
