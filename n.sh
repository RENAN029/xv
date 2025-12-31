#!/usr/bin/env bash
set -e

### ===== CONFIGURAÇÕES INICIAIS =====
read -p "Disco para instalação (ex: /dev/sda): " DISK
read -p "Hostname: " HOSTNAME
read -p "Usuário: " USERNAME

TIMEZONE="America/Sao_Paulo"

### ===== MENU DE DESKTOP =====
echo ""
echo "Selecione o ambiente desktop:"
select DE in "GNOME" "KDE Plasma" "XFCE" "Nenhum (Servidor/CLI)"; do
  case $REPLY in
    1) DESKTOP="gnome"; break ;;
    2) DESKTOP="plasma"; break ;;
    3) DESKTOP="xfce"; break ;;
    4) DESKTOP="none"; break ;;
    *) echo "Opção inválida";;
  esac
done

echo "Desktop selecionado: $DESKTOP"

### ===== PARTICIONAMENTO =====
echo ">>> Particionando disco"
parted $DISK -- mklabel gpt
parted $DISK -- mkpart ESP fat32 1MiB 512MiB
parted $DISK -- mkpart primary linux-swap 512MiB 8.5GiB
parted $DISK -- mkpart primary 8.5GiB 100%
parted $DISK -- set 1 boot on

### ===== FORMATAÇÃO =====
echo ">>> Formatando"
mkfs.fat -F32 ${DISK}1
mkswap ${DISK}2
mkfs.btrfs -f ${DISK}3

### ===== SUBVOLUMES BTRFS =====
mount ${DISK}3 /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@log
umount /mnt

### ===== MONTAGEM =====
mount -o subvol=@,compress=zstd ${DISK}3 /mnt
mkdir -p /mnt/{boot,home,nix,var/log}

mount -o subvol=@home,compress=zstd ${DISK}3 /mnt/home
mount -o subvol=@nix,compress=zstd ${DISK}3 /mnt/nix
mount -o subvol=@log,compress=zstd ${DISK}3 /mnt/var/log

mount ${DISK}1 /mnt/boot
swapon ${DISK}2

### ===== GERAR CONFIGURAÇÃO =====
nixos-generate-config --root /mnt

### ===== CONFIGURAÇÃO BASE =====
CONFIG="/mnt/etc/nixos/configuration.nix"

cat <<EOF >> $CONFIG

# ===== CONFIGURAÇÃO ADICIONADA PELO SCRIPT =====

networking.hostName = "$HOSTNAME";
time.timeZone = "$TIMEZONE";

boot.loader.systemd-boot.enable = true;
boot.loader.efi.canTouchEfiVariables = true;

networking.networkmanager.enable = true;

users.users.$USERNAME = {
  isNormalUser = true;
  extraGroups = [ "wheel" "networkmanager" ];
};

security.sudo.wheelNeedsPassword = false;

services.openssh.enable = true;

environment.systemPackages = with pkgs; [
  vim
  git
  curl
  wget
  htop
];

system.stateVersion = "24.05";
EOF

### ===== DESKTOP =====
if [ "$DESKTOP" != "none" ]; then
cat <<EOF >> $CONFIG

services.xserver.enable = true;
services.xserver.layout = "br";
services.xserver.xkbOptions = "grp:alt_shift_toggle";
EOF
fi

if [ "$DESKTOP" == "gnome" ]; then
cat <<EOF >> $CONFIG
services.xserver.displayManager.gdm.enable = true;
services.xserver.desktopManager.gnome.enable = true;
EOF
fi

if [ "$DESKTOP" == "plasma" ]; then
cat <<EOF >> $CONFIG
services.xserver.displayManager.sddm.enable = true;
services.xserver.desktopManager.plasma6.enable = true;
EOF
fi

if [ "$DESKTOP" == "xfce" ]; then
cat <<EOF >> $CONFIG
services.xserver.displayManager.lightdm.enable = true;
services.xserver.desktopManager.xfce.enable = true;
EOF
fi

### ===== INSTALAÇÃO =====
echo ">>> Instalando NixOS"
nixos-install --no-root-password

echo ""
echo "✅ Instalação finalizada com sucesso!"
echo "➡️ Reinicie com: reboot"
