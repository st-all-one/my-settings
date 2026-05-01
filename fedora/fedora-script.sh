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

echo "== Adicionando RPM Fusion non-free =="
sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-44.noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-44.noarch.rpm

echo "== Atualização básica =="
sudo dnf upgrade -y
flatpak update -y

echo "== Atualização de drivers e firmware =="
sudo fwupdmgr get-updates -y
sudo fwupdmgr update -y

echo "== Intalação de drivers =="
sudo dnf install -y mesa-va-drivers-freeworld

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
eza obs-studio chromium git-delta trash-cli fzf bat fd-find tldr

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

echo "== Limpeza pós-install =="
sudo dnf autoremove -y
sudo dnf clean all -y

echo "== Instalações manuais =="
echo ""
echo "curl -fsSL https://deno.land/install.sh | sh"
echo "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
