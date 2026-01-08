#!/bin/bash
set -e

[ ! -f /etc/arch-release ] && { echo "Apenas Arch Linux é suportado."; exit 1; }

STATE_DIR="$HOME/.config/arch_scripts"
mkdir -p "$STATE_DIR"

confirm() {
    local prompt="$1"
    read -p "$prompt (s/n): " -n 1 resposta
    echo
    [[ "$resposta" = "s" || "$resposta" = "S" ]]
}

cleanup_files() {
    local files=("$@")
    for file in "${files[@]}"; do
        [ -e "$file" ] && rm -rf "$file" || true
    done
}

cpu_ondemand() {
    local state_file="$STATE_DIR/cpu_ondemand"
    
    if [ -f "$state_file" ] || [ -f "/etc/systemd/system/set-ondemand-governor.service" ]; then
        if confirm "CPU Ondemand detectado. Desinstalar?"; then
            echo "Desinstalando CPU Ondemand..."
            
            sudo systemctl stop set-ondemand-governor.service 2>/dev/null || true
            sudo systemctl disable set-ondemand-governor.service 2>/dev/null || true
            
            sudo rm -f /etc/systemd/system/set-ondemand-governor.service 2>/dev/null || true
            sudo rm -f /etc/default/grub.d/01_intel_pstate_disable 2>/dev/null || true
            sudo rm -f /etc/kernel/cmdline.d/10-intel-pstate-disable.conf 2>/dev/null || true
            
            sudo rm -f /usr/local/bin/set-ondemand-governor.sh 2>/dev/null || true
            
            sudo grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || true
            sudo bootctl update 2>/dev/null || true
            
            cleanup_files "$state_file"
            echo "CPU Ondemand desinstalado. Reinicie para aplicar."
        fi
    else
        if confirm "Instalar CPU Ondemand?"; then
            echo "Instalando CPU Ondemand..."
            
            echo '#!/bin/bash
echo "ondemand" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor' | sudo tee /usr/local/bin/set-ondemand-governor.sh
            
            sudo chmod +x /usr/local/bin/set-ondemand-governor.sh
            
            echo '[Unit]
Description=Set CPU governor to ondemand
After=sysinit.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/set-ondemand-governor.sh

[Install]
WantedBy=multi-user.target' | sudo tee /etc/systemd/system/set-ondemand-governor.service
            
            sudo systemctl enable set-ondemand-governor.service
            
            sudo mkdir -p /etc/default/grub.d
            echo 'GRUB_CMDLINE_LINUX_DEFAULT="${GRUB_CMDLINE_LINUX_DEFAULT} intel_pstate=disable"' | sudo tee /etc/default/grub.d/01_intel_pstate_disable
            
            sudo grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || true
            
            touch "$state_file"
            echo "CPU Ondemand instalado. Reinicie para aplicar."
        fi
    fi
}

swapfile_create() {
    local location="$1"
    local size="$2"
    
    case $location in
        1)
            if findmnt -n -o FSTYPE / | grep -q "btrfs"; then
                sudo btrfs subvolume create /swap 2>/dev/null || true
                sudo btrfs filesystem mkswapfile --size ${size}g --uuid clear /swap/swapfile
                sudo swapon /swap/swapfile
                echo "/swap/swapfile none swap defaults 0 0" | sudo tee -a /etc/fstab
            else
                sudo dd if=/dev/zero of=/swapfile bs=1G count=$size status=progress 2>/dev/null || true
                sudo chmod 600 /swapfile
                sudo mkswap /swapfile
                sudo swapon /swapfile
                echo "/swapfile none swap defaults 0 0" | sudo tee -a /etc/fstab
            fi
            ;;
        2)
            if findmnt -n -o FSTYPE /home | grep -q "btrfs"; then
                sudo btrfs subvolume create /home/swap 2>/dev/null || true
                sudo btrfs filesystem mkswapfile --size ${size}g --uuid clear /home/swap/swapfile
                sudo swapon /home/swap/swapfile
                echo "/home/swap/swapfile none swap defaults 0 0" | sudo tee -a /etc/fstab
            else
                sudo dd if=/dev/zero of=/home/swapfile bs=1G count=$size status=progress 2>/dev/null || true
                sudo chmod 600 /home/swapfile
                sudo mkswap /home/swapfile
                sudo swapon /home/swapfile
                echo "/home/swapfile none swap defaults 0 0" | sudo tee -a /etc/fstab
            fi
            ;;
        *)
            echo "Opção inválida"
            return 1
            ;;
    esac
    
    echo "# swapfile" | sudo tee -a /etc/fstab
    return 0
}

swapfile() {
    local state_file="$STATE_DIR/swapfile"
    
    if [ -f "$state_file" ] || swapon --show | grep -q '.'; then
        if confirm "Swapfile detectado. Desinstalar?"; then
            echo "Desinstalando Swapfile..."
            
            sudo swapoff -a 2>/dev/null || true
            
            if [ -f "/swapfile" ]; then
                sudo swapoff /swapfile 2>/dev/null || true
                sudo rm -f /swapfile 2>/dev/null || true
                sudo sed -i '/\/swapfile/d' /etc/fstab 2>/dev/null || true
            fi
            
            if [ -f "/home/swapfile" ]; then
                sudo swapoff /home/swapfile 2>/dev/null || true
                sudo rm -f /home/swapfile 2>/dev/null || true
                sudo sed -i '/\/home\/swapfile/d' /etc/fstab 2>/dev/null || true
            fi
            
            if [ -d "/swap" ]; then
                sudo swapoff /swap/swapfile 2>/dev/null || true
                sudo rm -rf /swap 2>/dev/null || true
                sudo sed -i '/\/swap\/swapfile/d' /etc/fstab 2>/dev/null || true
            fi
            
            if [ -d "/home/swap" ]; then
                sudo swapoff /home/swap/swapfile 2>/dev/null || true
                sudo rm -rf /home/swap 2>/dev/null || true
                sudo sed -i '/\/home\/swap\/swapfile/d' /etc/fstab 2>/dev/null || true
            fi
            
            sudo sed -i '/# swapfile/d' /etc/fstab 2>/dev/null || true
            
            cleanup_files "$state_file"
            echo "Swapfile desinstalado."
        fi
    else
        echo "Onde criar o swapfile?"
        echo "1) / (root)"
        echo "2) /home"
        read -p "Opção: " location
        
        if [ "$location" != "1" ] && [ "$location" != "2" ]; then
            echo "Opção inválida"
            return
        fi
        
        read -p "Tamanho em GB (padrão: 8): " size
        size=${size:-8}
        
        if ! [[ "$size" =~ ^[0-9]+$ ]]; then
            echo "Tamanho inválido"
            return
        fi
        
        if confirm "Criar swapfile de ${size}GB?"; then
            echo "Criando swapfile de ${size}GB..."
            
            if swapfile_create "$location" "$size"; then
                touch "$state_file"
                echo "Swapfile criado com sucesso."
            fi
        fi
    fi
}

fish_basic() {
    local state_file="$STATE_DIR/fish_basic"
    local pkg_fish="fish"
    
    if [ -f "$state_file" ] || (pacman -Q fish &>/dev/null); then
        if confirm "Fish básico detectado. Desinstalar?"; then
            echo "Desinstalando Fish básico..."
            
            if pacman -Qq fish &>/dev/null; then
                sudo pacman -Rsnu --noconfirm $pkg_fish || true
            fi
            
            sudo chsh -s "$(which bash)" "$USER" 2>/dev/null || true
            
            cleanup_files "$state_file" "$HOME/.config/fish"
            echo "Fish básico desinstalado."
        fi
    else
        if confirm "Instalar Fish básico?"; then
            echo "Instalando Fish básico..."
            
            sudo pacman -S --noconfirm $pkg_fish
            sudo chsh -s "$(which fish)" "$USER"
            
            mkdir -p ~/.config/fish
            echo "set fish_greeting" > ~/.config/fish/config.fish
            
            touch "$state_file"
            echo "Fish básico instalado. Mensagem de boas-vindas removida."
        fi
    fi
}

fisher() {
    local state_file="$STATE_DIR/fisher"
    local pkg_fish="fish fisher"
    
    if [ -f "$state_file" ] || (pacman -Q fisher &>/dev/null); then
        if confirm "Fisher detectado. Desinstalar?"; then
            echo "Desinstalando Fisher..."
            
            if pacman -Qq fish fisher &>/dev/null; then
                sudo pacman -Rsnu --noconfirm $pkg_fish || true
            fi
            
            sudo chsh -s "$(which bash)" "$USER" 2>/dev/null || true
            
            cleanup_files "$state_file" "$HOME/.config/fish"
            echo "Fisher desinstalado."
        fi
    else
        if confirm "Instalar Fisher?"; then
            echo "Instalando Fisher..."
            
            sudo pacman -S --noconfirm $pkg_fish
            sudo chsh -s "$(which fish)" "$USER"
            
            mkdir -p ~/.config/fish
            echo "set fish_greeting" > ~/.config/fish/config.fish
            
            if command -v fish >/dev/null 2>&1; then
                fish -c "fisher install jorgebucaran/fisher" 2>/dev/null || true
            fi
            
            touch "$state_file"
            echo "Fisher instalado. Mensagem de boas-vindas removida."
        fi
    fi
}

fish_menu() {
    while true; do
        clear
        echo "=== Fish Shell ==="
        echo "1) Fish Básico (sem Fisher)"
        echo "2) Fish com Fisher"
        echo "3) Voltar"
        echo
        read -p "Selecione uma opção: " opcao
        
        case $opcao in
            1) clear; fish_basic ;;
            2) clear; fisher ;;
            3) return ;;
            *) ;;
        esac
        
        [ "$opcao" -ge 1 ] && [ "$opcao" -le 2 ] && read -p "Pressione Enter para continuar..."
    done
}

ufw() {
    local state_file="$STATE_DIR/ufw"
    local pkg_ufw="ufw"
    
    if [ -f "$state_file" ] || (pacman -Q ufw &>/dev/null); then
        if confirm "UFW detectado. Desinstalar?"; then
            echo "Desinstalando UFW..."
            
            if systemctl is-active --quiet ufw 2>/dev/null; then
                sudo systemctl stop ufw || true
            fi
            
            if systemctl is-enabled --quiet ufw 2>/dev/null; then
                sudo systemctl disable ufw || true
            fi
            
            if pacman -Qq ufw &>/dev/null; then
                sudo pacman -Rsnu --noconfirm $pkg_ufw || true
            fi
            
            sudo rm -rf /etc/ufw /lib/ufw /usr/share/ufw /var/lib/ufw 2>/dev/null || true
            sudo rm -f /usr/bin/ufw /usr/sbin/ufw 2>/dev/null || true
            
            cleanup_files "$state_file"
            echo "UFW desinstalado."
        fi
    else
        if confirm "Instalar UFW?"; then
            echo "Instalando UFW..."
            
            sudo pacman -S --noconfirm $pkg_ufw
            
            sudo ufw default deny incoming
            sudo ufw default allow outgoing
            sudo ufw allow 53317/udp
            sudo ufw allow 53317/tcp
            sudo ufw allow 1714:1764/udp
            sudo ufw allow 1714:1764/tcp
            
            sudo systemctl enable ufw
            sudo ufw --force enable
            
            sudo ufw status verbose
            touch "$state_file"
            echo "UFW instalado e configurado."
        fi
    fi
}

gamescope() {
    local state_file="$STATE_DIR/gamescope"
    local pkg_gamescope="gamescope"
    
    if [ -f "$state_file" ] || (pacman -Q gamescope &>/dev/null); then
        if confirm "Gamescope detectado. Desinstalar?"; then
            echo "Desinstalando Gamescope..."
            
            if pacman -Qq gamescope &>/dev/null; then
                sudo pacman -Rsnu --noconfirm $pkg_gamescope || true
            fi
            
            flatpak uninstall --user -y org.freedesktop.Platform.VulkanLayer.gamescope 2>/dev/null || true
            
            cleanup_files "$state_file"
            echo "Gamescope desinstalado."
        fi
    else
        if confirm "Instalar Gamescope?"; then
            echo "Instalando Gamescope..."
            
            sudo pacman -S --noconfirm $pkg_gamescope
            
            if command -v flatpak >/dev/null 2>&1; then
                flatpak install --user --noninteractive flathub org.freedesktop.Platform.VulkanLayer.gamescope 2>/dev/null || true
            fi
            
            touch "$state_file"
            echo "Gamescope instalado."
        fi
    fi
}

thumbnailer() {
    local state_file="$STATE_DIR/thumbnailer"
    local pkg_thumbnailer="ffmpegthumbnailer"
    
    if [ -f "$state_file" ] || (pacman -Q ffmpegthumbnailer &>/dev/null); then
        if confirm "Thumbnailer detectado. Desinstalar?"; then
            echo "Desinstalando Thumbnailer..."
            
            if pacman -Qq ffmpegthumbnailer &>/dev/null; then
                sudo pacman -Rsnu --noconfirm $pkg_thumbnailer || true
            fi
            
            cleanup_files "$state_file"
            echo "Thumbnailer desinstalado."
        fi
    else
        if confirm "Instalar Thumbnailer?"; then
            echo "Instalando Thumbnailer..."
            
            sudo pacman -S --noconfirm $pkg_thumbnailer
            touch "$state_file"
            echo "Thumbnailer instalado."
        fi
    fi
}

starship() {
    local state_file="$STATE_DIR/starship"
    local pkg_starship="starship"
    
    if [ -f "$state_file" ] || (pacman -Q starship &>/dev/null); then
        if confirm "Starship detectado. Desinstalar?"; then
            echo "Desinstalando Starship..."
            
            if pacman -Qq starship &>/dev/null; then
                sudo pacman -Rsnu --noconfirm $pkg_starship || true
            fi
            
            sed -i '/starship init/d' ~/.bashrc 2>/dev/null || true
            sed -i '/starship init/d' ~/.zshrc 2>/dev/null || true
            
            if [ -f ~/.config/fish/config.fish ]; then
                sed -i '/starship init fish/d' ~/.config/fish/config.fish 2>/dev/null || true
            fi
            
            cleanup_files "$state_file"
            echo "Starship desinstalado."
        fi
    else
        if confirm "Instalar Starship?"; then
            echo "Instalando Starship..."
            
            sudo pacman -S --noconfirm $pkg_starship
            
            if [ -f ~/.bashrc ]; then
                grep -q "starship init" ~/.bashrc || echo -e "\neval \"\$(starship init bash)\"" >> ~/.bashrc
            fi
            
            if [ -f ~/.zshrc ]; then
                grep -q "starship init" ~/.zshrc || echo -e "\neval \"\$(starship init zsh)\"" >> ~/.zshrc
            fi
            
            if command -v fish &>/dev/null; then
                mkdir -p ~/.config/fish
                if [ -f ~/.config/fish/config.fish ]; then
                    grep -q "starship init fish" ~/.config/fish/config.fish || echo -e "\nstarship init fish | source" >> ~/.config/fish/config.fish
                else
                    echo -e "starship init fish | source" >> ~/.config/fish/config.fish
                fi
            fi
            
            touch "$state_file"
            echo "Starship instalado com suporte para bash, zsh e fish."
        fi
    fi
}

nix_packages() {
    local state_file="$STATE_DIR/nix_packages"
    local pkg_nix="nix"
    
    if [ -f "$state_file" ] || (pacman -Q nix &>/dev/null) || [ -d "$HOME/.nix-profile" ]; then
        if confirm "Nix Packages detectado. Desinstalar?"; then
            echo "Desinstalando Nix Packages..."
            
            if pacman -Qq nix &>/dev/null; then
                sudo pacman -Rsnu --noconfirm $pkg_nix || true
            fi
            
            rm -rf "$HOME/.nix-profile" "$HOME/.nix-defexpr" "$HOME/.nix-channels" 2>/dev/null || true
            sudo rm -rf /nix /etc/nix /etc/profile.d/nix-daemon.sh 2>/dev/null || true
            
            sed -i '/nix-profile/d' ~/.bashrc ~/.profile ~/.bash_profile 2>/dev/null || true
            sed -i '/XDG_DATA_DIRS.*nix-profile/d' ~/.profile ~/.bash_profile 2>/dev/null || true
            sed -i '/source.*nix.sh/d' ~/.bashrc 2>/dev/null || true
            
            cleanup_files "$state_file"
            echo "Nix Packages desinstalado."
        fi
    else
        if confirm "Instalar Nix Packages?"; then
            echo "Instalando Nix Packages..."
            
            sudo pacman -S --noconfirm $pkg_nix
            
            if [ -f ~/.bashrc ]; then
                echo -e 'export PATH="$HOME/.nix-profile/bin:$PATH"' >> ~/.bashrc
            fi
            
            if [ -f ~/.profile ]; then
                echo -e 'export XDG_DATA_DIRS="$HOME/.nix-profile/share:$XDG_DATA_DIRS"' >> ~/.profile
            fi
            
            if [ -f ~/.bash_profile ]; then
                echo -e 'export XDG_DATA_DIRS="$HOME/.nix-profile/share:$XDG_DATA_DIRS"' >> ~/.bash_profile
            fi
            
            touch "$state_file"
            echo "Nix Packages instalado."
        fi
    fi
}

flathub() {
    local state_file="$STATE_DIR/flathub"
    local pkg_flatpak="flatpak"
    
    if [ -f "$state_file" ] || (pacman -Q flatpak &>/dev/null); then
        if confirm "Flathub detectado. Desinstalar?"; then
            echo "Desinstalando Flathub..."
            
            if pacman -Qq flatpak &>/dev/null; then
                sudo pacman -Rsnu --noconfirm $pkg_flatpak || true
            fi
            
            rm -rf "$HOME/.local/share/flatpak" 2>/dev/null || true
            sudo rm -rf /var/lib/flatpak 2>/dev/null || true
            
            cleanup_files "$state_file"
            echo "Flathub desinstalado."
        fi
    else
        if confirm "Instalar Flathub?"; then
            echo "Instalando Flathub..."
            
            sudo pacman -S --noconfirm $pkg_flatpak
            flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
            
            touch "$state_file"
            echo "Flathub instalado."
        fi
    fi
}

ananicy_cpp() {
    local state_file="$STATE_DIR/ananicy_cpp"
    local pkg_ananicy="ananicy-cpp cachyos-ananicy-rules-git"
    
    if [ -f "$state_file" ] || (pacman -Q ananicy-cpp &>/dev/null); then
        if confirm "Ananicy-cpp detectado. Desinstalar?"; then
            echo "Desinstalando Ananicy-cpp..."
            
            sudo systemctl stop ananicy-cpp.service 2>/dev/null || true
            sudo systemctl disable ananicy-cpp.service 2>/dev/null || true
            
            if pacman -Qq ananicy-cpp cachyos-ananicy-rules-git &>/dev/null; then
                sudo pacman -Rsnu --noconfirm $pkg_ananicy || true
            fi
            
            cleanup_files "$state_file"
            echo "Ananicy-cpp desinstalado."
        fi
    else
        if confirm "Instalar Ananicy-cpp?"; then
            echo "Instalando Ananicy-cpp..."
            
            sudo pacman -S --noconfirm $pkg_ananicy
            sudo systemctl enable --now ananicy-cpp.service
            touch "$state_file"
            echo "Ananicy-cpp instalado. Reinício recomendado."
        fi
    fi
}

hwaccel_flatpak() {
    local state_file="$STATE_DIR/hwaccel_flatpak"
    local pkg_flatpak="flatpak"
    
    if [ -f "$state_file" ] || (flatpak list | grep -q freedesktop.Platform.VAAPI 2>/dev/null); then
        if confirm "HW Acceleration Flatpak detectado. Desinstalar?"; then
            echo "Desinstalando HW Acceleration Flatpak..."
            
            flatpak uninstall --user -y freedesktop.Platform.VAAPI 2>/dev/null || true
            flatpak uninstall --user -y freedesktop.Platform.VAAPI.Intel 2>/dev/null || true
            
            cleanup_files "$state_file"
            echo "HW Acceleration Flatpak desinstalado."
        fi
    else
        if confirm "Instalar HW Acceleration Flatpak?"; then
            echo "Instalando HW Acceleration Flatpak..."
            
            if ! pacman -Q flatpak &>/dev/null; then
                sudo pacman -S --noconfirm $pkg_flatpak
                flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
            fi
            
            flatpak install --user -y flathub org.freedesktop.Platform.VAAPI.Intel 2>/dev/null || true
            flatpak override --user --device=all --env=GDK_SCALE=1 --env=GDK_DPI_SCALE=1 2>/dev/null || true
            touch "$state_file"
            echo "HW Acceleration Flatpak instalado."
        fi
    fi
}

appimage_fuse() {
    local state_file="$STATE_DIR/appimage_fuse"
    local pkg_fuse="fuse2 fuse3"
    
    if [ -f "$state_file" ] || (pacman -Q fuse2 &>/dev/null); then
        if confirm "FUSE para AppImage detectado. Desinstalar?"; then
            echo "Desinstalando FUSE para AppImage..."
            
            if pacman -Qq fuse2 &>/dev/null; then
                sudo pacman -Rsnu --noconfirm $pkg_fuse || true
            fi
            
            cleanup_files "$state_file"
            echo "FUSE para AppImage desinstalado."
        fi
    else
        if confirm "Instalar FUSE para AppImage?"; then
            echo "Instalando FUSE para AppImage..."
            
            sudo pacman -S --noconfirm $pkg_fuse
            touch "$state_file"
            echo "FUSE para AppImage instalado."
        fi
    fi
}

earlyoom() {
    local state_file="$STATE_DIR/earlyoom"
    local pkg_earlyoom="earlyoom"
    
    if [ -f "$state_file" ] || (pacman -Q earlyoom &>/dev/null); then
        if confirm "EarlyOOM detectado. Desinstalar?"; then
            echo "Desinstalando EarlyOOM..."
            
            sudo systemctl stop earlyoom 2>/dev/null || true
            sudo systemctl disable earlyoom 2>/dev/null || true
            
            if pacman -Qq earlyoom &>/dev/null; then
                sudo pacman -Rsnu --noconfirm $pkg_earlyoom || true
            fi
            
            cleanup_files "$state_file"
            echo "EarlyOOM desinstalado."
        fi
    else
        if confirm "Instalar EarlyOOM?"; then
            echo "Instalando EarlyOOM..."
            
            sudo pacman -S --noconfirm $pkg_earlyoom
            sudo systemctl enable earlyoom
            sudo systemctl start earlyoom
            
            touch "$state_file"
            echo "EarlyOOM instalado."
        fi
    fi
}

gamemode() {
    local state_file="$STATE_DIR/gamemode"
    local pkg_gamemode="gamemode lib32-gamemode"
    
    if [ -f "$state_file" ] || (pacman -Q gamemode &>/dev/null); then
        if confirm "Gamemode detectado. Desinstalar?"; then
            echo "Desinstalando Gamemode..."
            
            if pacman -Qq gamemode &>/dev/null; then
                sudo pacman -Rsnu --noconfirm $pkg_gamemode || true
            fi
            
            cleanup_files "$state_file"
            echo "Gamemode desinstalado."
        fi
    else
        if confirm "Instalar Gamemode?"; then
            echo "Instalando Gamemode..."
            
            sudo pacman -S --noconfirm $pkg_gamemode
            touch "$state_file"
            echo "Gamemode instalado."
        fi
    fi
}

oh_my_bash() {
    local state_file="$STATE_DIR/oh_my_bash"
    local osh_dir="$HOME/.oh-my-bash"
    
    if [ -f "$state_file" ] || [ -d "$osh_dir" ]; then
        if confirm "Oh My Bash detectado. Desinstalar?"; then
            echo "Desinstalando Oh My Bash..."
            
            if [ -d "$osh_dir" ]; then
                yes | "$osh_dir"/tools/uninstall.sh 2>/dev/null || true
            fi
            
            cleanup_files "$state_file"
            echo "Oh My Bash desinstalado."
        fi
    else
        if confirm "Instalar Oh My Bash?"; then
            echo "Instalando Oh My Bash..."
            
            bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" --unattended
            touch "$state_file"
            echo "Oh My Bash instalado."
        fi
    fi
}

nvim_basic() {
    local state_file="$STATE_DIR/nvim_basic"
    local pkg_neovim="neovim"
    
    if [ -f "$state_file" ] || (pacman -Q neovim &>/dev/null); then
        if confirm "NeoVim básico detectado. Desinstalar?"; then
            echo "Desinstalando NeoVim básico..."
            
            sudo pacman -Rsnu --noconfirm $pkg_neovim || true
            cleanup_files "$state_file"
            echo "NeoVim básico desinstalado."
        fi
    else
        if confirm "Instalar NeoVim básico?"; then
            echo "Instalando NeoVim básico..."
            
            sudo pacman -S --noconfirm $pkg_neovim
            touch "$state_file"
            echo "NeoVim básico instalado."
        fi
    fi
}

nvim_lazyman() {
    local state_file="$STATE_DIR/nvim_lazyman"
    local pkg_neovim="neovim git"
    local lazyman_dir="$HOME/.config/nvim-Lazyman"
    
    if [ -f "$state_file" ] || [ -d "$lazyman_dir" ]; then
        if confirm "Lazyman detectado. Desinstalar?"; then
            echo "Desinstalando Lazyman..."
            
            cleanup_files "$state_file" "$lazyman_dir"
            echo "Lazyman desinstalado."
        fi
    else
        if confirm "Instalar Lazyman?"; then
            echo "Instalando Lazyman..."
            
            sudo pacman -S --noconfirm $pkg_neovim
            
            git clone --depth=1 https://github.com/doctorfree/nvim-lazyman "$lazyman_dir"
            
            echo "Selecione a configuração:"
            echo "1) Abstract"
            echo "2) AstroNvimPlus"
            echo "3) Basic IDE"
            echo "4) Ecovim"
            echo "5) LazyVim"
            echo "6) LunarVim"
            echo "7) MagicVim"
            echo "8) NvChad"
            echo "9) SpaceVim"
            read -p "Opção (1-9): " config_opcao
            
            case $config_opcao in
                1) "$lazyman_dir"/lazyman.sh -g -z ;;
                2) "$lazyman_dir"/lazyman.sh -a -z ;;
                3) "$lazyman_dir"/lazyman.sh -j -z ;;
                4) "$lazyman_dir"/lazyman.sh -e -z ;;
                5) "$lazyman_dir"/lazyman.sh -l -z ;;
                6) "$lazyman_dir"/lazyman.sh -v -z ;;
                7) "$lazyman_dir"/lazyman.sh -m -z ;;
                8) "$lazyman_dir"/lazyman.sh -c -z ;;
                9) "$lazyman_dir"/lazyman.sh -s -z ;;
                *) echo "Opção inválida" ;;
            esac
            
            touch "$state_file"
            echo "Lazyman instalado."
        fi
    fi
}

nvim_lazyvim() {
    local state_file="$STATE_DIR/nvim_lazyvim"
    local nvim_dir="$HOME/.config/nvim"
    
    if [ -f "$state_file" ] || [ -d "$nvim_dir" ]; then
        if confirm "LazyVim detectado. Desinstalar?"; then
            echo "Desinstalando LazyVim..."
            
            cleanup_files "$state_file" "$nvim_dir"
            echo "LazyVim desinstalado."
        fi
    else
        if confirm "Instalar LazyVim?"; then
            echo "Instalando LazyVim..."
            
            git clone https://github.com/LazyVim/starter "$nvim_dir"
            rm -rf "$nvim_dir/.git"
            touch "$state_file"
            echo "LazyVim instalado."
        fi
    fi
}

nvim() {
    while true; do
        clear
        echo "=== NeoVim ==="
        echo "1) NeoVim Básico"
        echo "2) Lazyman"
        echo "3) LazyVim Direto"
        echo "4) Voltar"
        echo
        read -p "Selecione uma opção: " opcao
        
        case $opcao in
            1) clear; nvim_basic ;;
            2) clear; nvim_lazyman ;;
            3) clear; nvim_lazyvim ;;
            4) return ;;
            *) ;;
        esac
        
        [ "$opcao" -ge 1 ] && [ "$opcao" -le 3 ] && read -p "Pressione Enter para continuar..."
    done
}

de_cosmic() {
    local state_file="$STATE_DIR/de_cosmic"
    local pkg_base="noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-noto-nerd noto-fonts-extra ttf-jetbrains-mono"
    local pkg_media="ffmpeg gst-plugins-ugly gst-plugins-good gst-plugins-base gst-plugins-bad gst-libav gstreamer"
    local pkg_cosmic="cosmic-session cosmic-terminal cosmic-files cosmic-store cosmic-wallpapers xdg-user-dirs croc gdu"
    
    if [ -f "$state_file" ] || (pacman -Q cosmic-session &>/dev/null); then
        if confirm "Cosmic detectado. Desinstalar?"; then
            echo "Desinstalando Cosmic..."
            
            sudo systemctl disable cosmic-greeter 2>/dev/null || true
            sudo pacman -Rsnu --noconfirm $pkg_cosmic || true
            sudo pacman -Rsnu --noconfirm $pkg_media || true
            sudo pacman -Rsnu --noconfirm $pkg_base || true
            
            cleanup_files "$state_file"
            echo "Cosmic desinstalado."
        fi
    else
        if confirm "Instalar Cosmic?"; then
            echo "Instalando Cosmic..."
            
            sudo pacman -S --noconfirm $pkg_base
            sudo pacman -S --noconfirm $pkg_media
            sudo pacman -S --noconfirm $pkg_cosmic
            sudo systemctl enable cosmic-greeter
            
            touch "$state_file"
            echo "Cosmic instalado. Reinicie para aplicar."
        fi
    fi
}

de_gnome() {
    local state_file="$STATE_DIR/de_gnome"
    local pkg_base="noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-noto-nerd noto-fonts-extra ttf-jetbrains-mono"
    local pkg_media="ffmpeg gst-plugins-ugly gst-plugins-good gst-plugins-base gst-plugins-bad gst-libav gstreamer"
    local pkg_gnome="gnome-shell gnome-console gnome-software gnome-tweaks gnome-control-center gnome-disk-utility gdm"
    
    if [ -f "$state_file" ] || (pacman -Q gnome-shell &>/dev/null); then
        if confirm "Gnome detectado. Desinstalar?"; then
            echo "Desinstalando Gnome..."
            
            sudo systemctl disable gdm 2>/dev/null || true
            sudo pacman -Rsnu --noconfirm $pkg_gnome || true
            sudo pacman -Rsnu --noconfirm $pkg_media || true
            sudo pacman -Rsnu --noconfirm $pkg_base || true
            
            cleanup_files "$state_file"
            echo "Gnome desinstalado."
        fi
    else
        if confirm "Instalar Gnome?"; then
            echo "Instalando Gnome..."
            
            sudo pacman -S --noconfirm $pkg_base
            sudo pacman -S --noconfirm $pkg_media
            sudo pacman -S --noconfirm $pkg_gnome
            sudo systemctl enable gdm
            
            touch "$state_file"
            echo "Gnome instalado. Reinicie para aplicar."
        fi
    fi
}

de_plasma() {
    local state_file="$STATE_DIR/de_plasma"
    local pkg_base="noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-noto-nerd noto-fonts-extra ttf-jetbrains-mono"
    local pkg_media="ffmpeg gst-plugins-ugly gst-plugins-good gst-plugins-base gst-plugins-bad gst-libav gstreamer"
    local pkg_plasma="plasma-meta konsole dolphin discover kdeconnect partitionmanager ffmpegthumbs dolphin-plugins ark"
    
    if [ -f "$state_file" ] || (pacman -Q plasma-meta &>/dev/null); then
        if confirm "Plasma detectado. Desinstalar?"; then
            echo "Desinstalando Plasma..."
            
            sudo systemctl disable sddm 2>/dev/null || true
            sudo pacman -Rsnu --noconfirm $pkg_plasma || true
            sudo pacman -Rsnu --noconfirm $pkg_media || true
            sudo pacman -Rsnu --noconfirm $pkg_base || true
            
            cleanup_files "$state_file"
            echo "Plasma desinstalado."
        fi
    else
        if confirm "Instalar Plasma?"; then
            echo "Instalando Plasma..."
            
            sudo pacman -S --noconfirm $pkg_base
            sudo pacman -S --noconfirm $pkg_media
            sudo pacman -S --noconfirm $pkg_plasma
            sudo systemctl enable sddm
            
            touch "$state_file"
            echo "Plasma instalado. Reinicie para aplicar."
        fi
    fi
}

de() {
    while true; do
        clear
        echo "=== Ambientes Desktop ==="
        echo "1) Cosmic"
        echo "2) Gnome"
        echo "3) Plasma"
        echo "4) Voltar"
        echo
        read -p "Selecione uma opção: " opcao
        
        case $opcao in
            1) clear; de_cosmic ;;
            2) clear; de_gnome ;;
            3) clear; de_plasma ;;
            4) return ;;
            *) ;;
        esac
        
        [ "$opcao" -ge 1 ] && [ "$opcao" -le 3 ] && read -p "Pressione Enter para continuar..."
    done
}

apparmor() {
    local state_file="$STATE_DIR/apparmor"
    local pkg_apparmor="apparmor"
    
    if [ -f "$state_file" ] || (pacman -Q apparmor &>/dev/null); then
        if confirm "AppArmor detectado. Desinstalar?"; then
            echo "Desinstalando AppArmor..."
            
            sudo systemctl stop apparmor 2>/dev/null || true
            sudo systemctl disable apparmor 2>/dev/null || true
            
            sudo rm -f /etc/default/grub.d/99-apparmor.cfg 2>/dev/null || true
            sudo rm -f /etc/kernel/cmdline.d/99-apparmor.conf 2>/dev/null || true
            
            if pacman -Qq grub &>/dev/null; then
                sudo grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || true
            else
                sudo bootctl update 2>/dev/null || true
            fi
            
            if pacman -Qq apparmor &>/dev/null; then
                sudo pacman -Rsnu --noconfirm $pkg_apparmor || true
            fi
            
            cleanup_files "$state_file"
            echo "AppArmor desinstalado."
        fi
    else
        if confirm "Instalar AppArmor?"; then
            echo "Instalando AppArmor..."
            
            sudo pacman -S --noconfirm $pkg_apparmor
            
            if pacman -Qq grub &>/dev/null; then
                sudo mkdir -p /etc/default/grub.d
                echo 'GRUB_CMDLINE_LINUX_DEFAULT="${GRUB_CMDLINE_LINUX_DEFAULT} apparmor=1 security=apparmor"' | sudo tee /etc/default/grub.d/99-apparmor.cfg
                sudo grub-mkconfig -o /boot/grub/grub.cfg
            else
                sudo mkdir -p /etc/kernel/cmdline.d
                echo "apparmor=1 security=apparmor" | sudo tee /etc/kernel/cmdline.d/99-apparmor.conf
                sudo bootctl update 2>/dev/null || true
            fi
            
            sudo systemctl enable apparmor
            touch "$state_file"
            echo "AppArmor instalado. Reinicie para aplicar."
        fi
    fi
}

chaotic_aur() {
    local state_file="$STATE_DIR/chaotic_aur"
    local pkg_chaotic="chaotic-keyring chaotic-mirrorlist"
    
    if [ -f "$state_file" ] || (pacman -Q chaotic-keyring &>/dev/null && pacman -Q chaotic-mirrorlist &>/dev/null); then
        if confirm "Chaotic AUR detectado. Desinstalar?"; then
            echo "Desinstalando Chaotic AUR..."
            
            sudo sed -i '/\[chaotic-aur\]/,/^$/d' /etc/pacman.conf 2>/dev/null || true
            
            if pacman -Qq chaotic-keyring chaotic-mirrorlist &>/dev/null; then
                sudo pacman -Rsnu --noconfirm $pkg_chaotic || true
            fi
            
            sudo pacman-key --delete 3056513887B78AEB 2>/dev/null || true
            sudo sed -i '/^ILoveCandy/d' /etc/pacman.conf 2>/dev/null || true
            sudo sed -i '/^ParallelDownloads/d' /etc/pacman.conf 2>/dev/null || true
            
            cleanup_files "$state_file"
            echo "Chaotic AUR desinstalado."
        fi
    else
        if confirm "Instalar Chaotic AUR?"; then
            echo "Instalando Chaotic AUR..."
            
            sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
            sudo pacman-key --lsign-key 3056513887B78AEB
            
            sudo pacman -U --noconfirm \
                "https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst" \
                "https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst"
            
            sudo sed -i 's/^#Color/Color/' /etc/pacman.conf
            sudo sed -i '/Color/a ILoveCandy' /etc/pacman.conf
            sudo sed -i '/^ParallelDownloads/d' /etc/pacman.conf
            sudo sed -i '/ILoveCandy/a ParallelDownloads = 15' /etc/pacman.conf
            
            echo -e "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" | sudo tee -a /etc/pacman.conf
            
            sudo pacman -Syu
            touch "$state_file"
            echo "Chaotic AUR instalado."
        fi
    fi
}

dnsmasq() {
    local state_file="$STATE_DIR/dnsmasq"
    local pkg_dnsmasq="dnsmasq"
    
    if [ -f "$state_file" ] || (pacman -Q dnsmasq &>/dev/null); then
        if confirm "DNSMasq detectado. Desinstalar?"; then
            echo "Desinstalando DNSMasq..."
            
            sudo systemctl stop dnsmasq 2>/dev/null || true
            sudo systemctl disable dnsmasq 2>/dev/null || true
            
            if pacman -Qq dnsmasq &>/dev/null; then
                sudo pacman -Rsnu --noconfirm $pkg_dnsmasq || true
            fi
            
            sudo rm -rf /etc/dnsmasq.d /etc/dnsmasq.conf 2>/dev/null || true
            cleanup_files "$state_file"
            echo "DNSMasq desinstalado."
        fi
    else
        if confirm "Instalar DNSMasq?"; then
            echo "Instalando DNSMasq..."
            
            sudo pacman -S --noconfirm $pkg_dnsmasq
            sudo systemctl enable dnsmasq
            touch "$state_file"
            echo "DNSMasq instalado."
        fi
    fi
}

lucidglyph() {
    local state_file="$STATE_DIR/lucidglyph"
    
    if [ -f "$state_file" ] || \
       [ -f "/usr/share/lucidglyph/info" ] || \
       [ -f "/usr/share/freetype-envision/info" ] || \
       [ -f "$HOME/.local/share/lucidglyph/info" ] || \
       { [ -d "/etc/fonts/conf.d" ] && find "/etc/fonts/conf.d" -name "*lucidglyph*" -o -name "*freetype-envision*" 2>/dev/null | grep -q .; }; then
        
        if confirm "LucidGlyph detectado. Desinstalar?"; then
            echo "Desinstalando LucidGlyph..."
            
            for uninstaller in "/usr/share/lucidglyph/uninstaller.sh" \
                              "/usr/share/freetype-envision/uninstaller.sh" \
                              "$HOME/.local/share/lucidglyph/uninstaller.sh"; do
                if [ -f "$uninstaller" ] && [ -x "$uninstaller" ]; then
                    sudo "$uninstaller" || true
                    break
                fi
            done
            
            cleanup_files "$state_file"
            sudo rm -f /etc/fonts/conf.d/*lucidglyph* /etc/fonts/conf.d/*freetype-envision* 2>/dev/null || true
            rm -f "$HOME/.config/fontconfig/conf.d/"*lucidglyph* "$HOME/.config/fontconfig/conf.d/"*freetype-envision* 2>/dev/null || true
            sudo sed -i '/LUCIDGLYPH\|FREETYPE_ENVISION/d' /etc/environment 2>/dev/null || true
            sudo fc-cache -f || true
            echo "LucidGlyph desinstalado."
        fi
    else
        if confirm "Instalar LucidGlyph?"; then
            echo "Instalando LucidGlyph..."
            
            local tag=$(curl -s "https://api.github.com/repos/maximilionus/lucidglyph/releases/latest" | grep -oP '"tag_name": "\K(.*)(?=")')
            local ver="${tag#v}"
            
            cd "$HOME" || exit 1
            cleanup_files "${tag}.tar.gz" "lucidglyph-${ver}"
            
            curl -L -o "${tag}.tar.gz" "https://github.com/maximilionus/lucidglyph/archive/refs/tags/${tag}.tar.gz"
            tar -xvzf "${tag}.tar.gz"
            cd "lucidglyph-${ver}" || exit 1
            
            chmod +x lucidglyph.sh
            sudo ./lucidglyph.sh install
            
            cd .. || exit 1
            cleanup_files "${tag}.tar.gz" "lucidglyph-${ver}"
            
            touch "$state_file"
            echo "LucidGlyph instalado."
        fi
    fi
}

shader_booster() {
    local state_file="$STATE_DIR/shader_booster"
    local boost_file="$HOME/.booster"
    
    if [ -f "$state_file" ] || [ -f "$boost_file" ]; then
        if confirm "Shader Booster detectado. Desinstalar?"; then
            echo "Desinstalando Shader Booster..."
            
            for shell_file in "$HOME/.bash_profile" "$HOME/.profile" "$HOME/.zshrc"; do
                if [ -f "$shell_file" ]; then
                    sed -i '/# Shader Booster patches/,/# End Shader Booster/d' "$shell_file" 2>/dev/null || true
                fi
            done
            
            cleanup_files "$state_file" "$boost_file" "$HOME/patch-nvidia" "$HOME/patch-mesa"
            echo "Shader Booster desinstalado."
        fi
    else
        if confirm "Instalar Shader Booster?"; then
            echo "Instalando Shader Booster..."
            
            local has_nvidia=$(lspci | grep -i 'nvidia')
            local has_mesa=$(lspci | grep -Ei '(vga|3d)' | grep -vi nvidia)
            local patch_applied=0
            
            local dest_file=""
            for file in "$HOME/.bash_profile" "$HOME/.profile" "$HOME/.zshrc"; do
                if [ -f "$file" ]; then
                    dest_file="$file"
                    break
                fi
            done
            
            if [ -z "$dest_file" ]; then
                dest_file="$HOME/.bash_profile"
                touch "$dest_file"
            fi
            
            echo -e "\n# Shader Booster patches" >> "$dest_file"
            
            if [ -n "$has_nvidia" ]; then
                echo "Aplicando patch para NVIDIA..."
                curl -s https://raw.githubusercontent.com/psygreg/shader-booster/main/patch-nvidia >> "$dest_file"
                patch_applied=1
            fi
            
            if [ -n "$has_mesa" ]; then
                echo "Aplicando patch para Mesa..."
                curl -s https://raw.githubusercontent.com/psygreg/shader-booster/main/patch-mesa >> "$dest_file"
                patch_applied=1
            fi
            
            echo "# End Shader Booster" >> "$dest_file"
            
            if [ $patch_applied -eq 1 ]; then
                echo "1" > "$boost_file"
                touch "$state_file"
                echo "Shader Booster instalado. Reinicie para aplicar."
            else
                echo "Nenhuma GPU compatível detectada."
            fi
        fi
    fi
}

main() {
    while true; do
        clear
        echo "=== Scripts para Arch Linux ==="
        echo "1) Ambientes Desktop"
        echo "2) Ananicy-cpp"
        echo "3) AppArmor"
        echo "4) AppImage FUSE"
        echo "5) Chaotic AUR"
        echo "6) CPU Ondemand"
        echo "7) DNSMasq"
        echo "8) EarlyOOM"
        echo "9) Fish Shell"
        echo "10) Flathub"
        echo "11) Gamemode"
        echo "12) Gamescope"
        echo "13) HW Acceleration Flatpak"
        echo "14) LucidGlyph"
        echo "15) NeoVim"
        echo "16) Nix Packages"
        echo "17) Oh My Bash"
        echo "18) Shader Booster"
        echo "19) Starship"
        echo "20) Swapfile"
        echo "21) Thumbnailer"
        echo "22) UFW"
        echo "23) Sair"
        echo
        read -p "Selecione uma opção: " opcao
        
        case $opcao in
            1) clear; de ;;
            2) clear; ananicy_cpp ;;
            3) clear; apparmor ;;
            4) clear; appimage_fuse ;;
            5) clear; chaotic_aur ;;
            6) clear; cpu_ondemand ;;
            7) clear; dnsmasq ;;
            8) clear; earlyoom ;;
            9) clear; fish_menu ;;
            10) clear; flathub ;;
            11) clear; gamemode ;;
            12) clear; gamescope ;;
            13) clear; hwaccel_flatpak ;;
            14) clear; lucidglyph ;;
            15) clear; nvim ;;
            16) clear; nix_packages ;;
            17) clear; oh_my_bash ;;
            18) clear; shader_booster ;;
            19) clear; starship ;;
            20) clear; swapfile ;;
            21) clear; thumbnailer ;;
            22) clear; ufw ;;
            23) exit 0 ;;
            *) ;;
        esac
        
        [ "$opcao" -ge 1 ] && [ "$opcao" -le 22 ] && read -p "Pressione Enter para continuar..."
    done
}

main
