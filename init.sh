#!/usr/bin/env bash
set -euo pipefail

# Disable cros-motd
sudo bash - << EOF
echo 'DPkg::Post-Invoke {"rm -f /etc/profile.d/cros-motd.sh";};' >> /etc/apt/apt.conf.d/99blacklist
rm -f /etc/profile.d/cros-motd.sh
rm -f ~$USER/.local/share/cros-motd
EOF

# Update
sudo bash - << EOF
apt-get update
apt-get -y dist-upgrade
EOF

# Vim
sudo bash - << EOF
echo 'DPkg::Post-Invoke {"rm -f /usr/share/applications/vim.desktop";};' >> /etc/apt/apt.conf.d/99blacklist
apt-get -y reinstall vim
cat << 'VIMRC' >> /etc/vim/vimrc.local
let g:skip_defaults_vim = 1
set mouse=
set expandtab
set tabstop=2
set softtabstop=2
set shiftwidth=2
syntax on
VIMRC
EOF

# Fish
sudo bash - << EOF
echo 'DPkg::Post-Invoke {"rm -f /usr/share/applications/fish.desktop";};' >> /etc/apt/apt.conf.d/99blacklist
apt-get -y install fish
echo 'set fish_greeting' > /etc/fish/conf.d/greeting.fish
usermod -s /usr/bin/fish root
usermod -s /usr/bin/fish $USER
EOF

# Environment
sudo bash - << EOF
cat << 'ENVIRONMENT' > /etc/environment.d/00init.conf
XDG_CONFIG_HOME=\$HOME/.config
XDG_DATA_DIRS=\$HOME/.local/share:/usr/local/share:/usr/share
ENVIRONMENT
EOF

# Garcon
sudo bash - << EOF
cat << 'CROS_GARCON' > /etc/systemd/user/cros-garcon.service.d/override.conf
[Service]
Environment=
Environment="BROWSER=/usr/bin/garcon-url-handler"
Environment="NCURSES_NO_UTF8_ACS=1"
Environment="QT_AUTO_SCREEN_SCALE_FACTOR=1"
Environment="QT_QPA_PLATFORMTHEME=gtk2"
Environment="XCURSOR_THEME=Adwaita"
Environment="XDG_CURRENT_DESKTOP=X-Generic"
Environment="XDG_SESSION_TYPE=wayland"
Environment="ELECTRON_OZONE_PLATFORM_HINT=wayland"
CROS_GARCON
EOF

# Sommelier
sudo bash - << EOF
sed -i '/SOMMELIER_ACCELERATORS/d' /etc/systemd/user/sommelier*.service.d/cros-sommelier-*.conf
cat << 'ENVIRONMENT' > /etc/environment.d/50sommelier.conf
SOMMELIER_ACCELERATORS=Super_L,<Alt>bracketleft,<Alt>bracketright,<Alt>tab,<Alt>equal,<Alt>bracketleft,<Alt>bracketright,<Control><Alt>comma,<Control><Alt>period
ENVIRONMENT
EOF

# Podman
sudo bash - << EOF
usermod -v 1000000-1999999 -w 1000000-1999999 $USER
apt-get -y install podman
EOF

# Nix
sudo bash - << EOF
sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) \
  --daemon \
  --no-channel-add \
  --no-modify-profile \
  --yes \
  --nix-extra-conf-file <(echo "experimental-features = nix-command flakes")
EOF

# Clean
sudo bash - << EOF
apt-get -y autoremove
apt-get clean
EOF

# Reboot
echo
echo "Please reboot to continue..."
