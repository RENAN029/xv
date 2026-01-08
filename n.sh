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
                sudo pacman -Rsnu --noconfirm apparmor || true
            fi
            
            cleanup_files "$state_file"
            echo "AppArmor desinstalado."
        fi
    else
        if confirm "Instalar AppArmor?"; then
            echo "Instalando AppArmor..."
            
            sudo pacman -S --noconfirm apparmor
            
            if pacman -Qq grub &>/dev/null; then
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
    
    if [ -f "$state_file" ] || (pacman -Q chaotic-keyring &>/dev/null && pacman -Q chaotic-mirrorlist &>/dev/null); then
        if confirm "Chaotic AUR detectado. Desinstalar?"; then
            echo "Desinstalando Chaotic AUR..."
            
            sudo sed -i '/\[chaotic-aur\]/,/^$/d' /etc/pacman.conf 2>/dev/null || true
            
            if pacman -Qq chaotic-keyring chaotic-mirrorlist &>/dev/null; then
                sudo pacman -Rsnu --noconfirm chaotic-keyring chaotic-mirrorlist || true
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
    
    if [ -f "$state_file" ] || (pacman -Q dnsmasq &>/dev/null); then
        if confirm "DNSMasq detectado. Desinstalar?"; then
            echo "Desinstalando DNSMasq..."
            
            sudo systemctl stop dnsmasq 2>/dev/null || true
            sudo systemctl disable dnsmasq 2>/dev/null || true
            
            if pacman -Qq dnsmasq &>/dev/null; then
                sudo pacman -Rsnu --noconfirm dnsmasq || true
            fi
            
            sudo rm -rf /etc/dnsmasq.d /etc/dnsmasq.conf 2>/dev/null || true
            cleanup_files "$state_file"
            echo "DNSMasq desinstalado."
        fi
    else
        if confirm "Instalar DNSMasq?"; then
            echo "Instalando DNSMasq..."
            
            sudo pacman -S --noconfirm dnsmasq
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

ufw() {
    local state_file="$STATE_DIR/ufw"
    local pkg_ufw="ufw gufw"
    
    if [ -f "$state_file" ] || (pacman -Q ufw &>/dev/null); then
        if confirm "UFW detectado. Desinstalar?"; then
            echo "Desinstalando UFW..."
            
            if systemctl is-active --quiet ufw 2>/dev/null; then
                sudo systemctl stop ufw || true
            fi
            
            if systemctl is-enabled --quiet ufw 2>/dev/null; then
                sudo systemctl disable ufw || true
            fi
            
            sudo pacman -Rsnu --noconfirm $pkg_ufw || true
            
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

main() {
    while true; do
        clear
        echo "=== Scripts para Arch Linux ==="
        echo "1) Ambiente Desktop"
        echo "2) AppArmor"
        echo "3) Chaotic AUR"
        echo "4) DNSMasq"
        echo "5) LucidGlyph"
        echo "6) Shader Booster"
        echo "7) UFW"
        echo "8) Sair"
        echo
        read -p "Selecione uma opção: " opcao
        
        case $opcao in
            1) clear; de ;;
            2) clear; apparmor ;;
            3) clear; chaotic_aur ;;
            4) clear; dnsmasq ;;
            5) clear; lucidglyph ;;
            6) clear; shader_booster ;;
            7) clear; ufw ;;
            8) exit 0 ;;
            *) ;;
        esac
        
        [ "$opcao" -ge 1 ] && [ "$opcao" -le 7 ] && read -p "Pressione Enter para continuar..."
    done
}

main
