#!/bin/bash
set -e
[ ! -f /etc/arch-release ] && echo "Arch apenas" && exit 1

main() {
    while true; do
        clear
        echo "1) LucidGlyph"
        echo "2) Shader Booster"
        echo "3) UFW Firewall"
        echo "4) Chaotic AUR"
        echo "5) Desktop Environment"
        echo "6) Neovim"
        echo "7) Oh My Bash"
        echo "8) Sair"
        read -p "> " o
        case $o in
            1) lucidglyph ;;
            2) shader_booster ;;
            3) ufw_firewall ;;
            4) chaotic_aur ;;
            5) desktop_environment ;;
            6) neovim_menu ;;
            7) oh_my_bash ;;
            8) exit ;;
            *) ;;
        esac
    done
}

chaotic_aur() {
    clear
    if grep -q "\[chaotic-aur\]" /etc/pacman.conf 2>/dev/null; then
        echo "Chaotic AUR detectado"
        read -p "Desinstalar? (s/n): " -n 1 r
        echo
        [ "$r" != "s" ] && return
        
        if [ "$EUID" -ne 0 ]; then
            echo "Execute com sudo: sudo $0"
            read -p "..."
            return
        fi
        
        sed -i '/\[chaotic-aur\]/,+2d' /etc/pacman.conf 2>/dev/null || true
        rm -f /etc/pacman.d/chaotic-mirrorlist 2>/dev/null || true
        rm -f /usr/share/pacman/keyrings/chaotic.* 2>/dev/null || true
        pacman -Rns --noconfirm chaotic-keyring chaotic-mirrorlist 2>/dev/null || true
        echo "Desinstalado"
    else
        echo "Chaotic AUR não detectado"
        read -p "Instalar? (s/n): " -n 1 r
        echo
        [ "$r" != "s" ] && return
        
        if [ "$EUID" -ne 0 ]; then
            echo "Execute com sudo: sudo $0"
            read -p "..."
            return
        fi
        
        echo "Instalando Chaotic AUR..."
        pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com 2>/dev/null || true
        pacman-key --lsign-key 3056513887B78AEB 2>/dev/null || true
        pacman -U --noconfirm "https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst" 2>/dev/null || true
        pacman -U --noconfirm "https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst" 2>/dev/null || true
        
        sed -i 's/^#Color/Color/' /etc/pacman.conf 2>/dev/null || true
        grep -q "ILoveCandy" /etc/pacman.conf || sed -i '/Color/a ILoveCandy' /etc/pacman.conf 2>/dev/null || true
        sed -i '/^ParallelDownloads/d' /etc/pacman.conf 2>/dev/null || true
        grep -q "ParallelDownloads" /etc/pacman.conf || sed -i '/ILoveCandy/a ParallelDownloads = 15' /etc/pacman.conf 2>/dev/null || true
        grep -q "\[chaotic-aur\]" /etc/pacman.conf || echo -e "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" >> /etc/pacman.conf 2>/dev/null || true
        
        echo "Configurado"
    fi
    read -p "..."
}

desktop_environment() {
    clear
    
    if [ "$EUID" -ne 0 ]; then
        echo "Execute com sudo: sudo $0"
        read -p "..."
        return
    fi
    
    echo "Desktop Environments disponíveis:"
    
    local cosmic_installed=0
    local gnome_installed=0
    local kde_installed=0
    
    pacman -Q cosmic-session 2>/dev/null | grep -q cosmic-session && cosmic_installed=1
    pacman -Q gnome-shell 2>/dev/null | grep -q gnome-shell && gnome_installed=1
    pacman -Q plasma-meta 2>/dev/null | grep -q plasma-meta && kde_installed=1
    
    if [ $cosmic_installed -eq 1 ]; then
        echo "1) Desinstalar Cosmic"
    else
        echo "1) Instalar Cosmic"
    fi
    
    if [ $gnome_installed -eq 1 ]; then
        echo "2) Desinstalar GNOME"
    else
        echo "2) Instalar GNOME"
    fi
    
    if [ $kde_installed -eq 1 ]; then
        echo "3) Desinstalar KDE Plasma"
    else
        echo "3) Instalar KDE Plasma"
    fi
    
    echo "4) Voltar"
    read -p "> " o
    
    case $o in
        1) [ $cosmic_installed -eq 1 ] && uninstall_cosmic || install_cosmic ;;
        2) [ $gnome_installed -eq 1 ] && uninstall_gnome || install_gnome ;;
        3) [ $kde_installed -eq 1 ] && uninstall_kde || install_kde ;;
        4) return ;;
        *) echo "Opção inválida" ;;
    esac
    
    read -p "..."
}

detect_lucidglyph() {
    [ -f "/usr/share/lucidglyph/info" ] && return 0
    [ -f "/usr/share/freetype-envision/info" ] && return 0
    [ -f "$HOME/.local/share/lucidglyph/info" ] && return 0
    [ -d "/etc/fonts/conf.d" ] && find "/etc/fonts/conf.d" -name "*lucidglyph*" -o -name "*freetype-envision*" 2>/dev/null | grep -q . && return 0
    [ -d "$HOME/.config/fontconfig/conf.d" ] && find "$HOME/.config/fontconfig/conf.d" -name "*lucidglyph*" -o -name "*freetype-envision*" 2>/dev/null | grep -q . && return 0
    [ -f "/etc/environment" ] && grep -q "LUCIDGLYPH\|FREETYPE_ENVISION" "/etc/environment" 2>/dev/null && return 0
    return 1
}

install_cosmic() {
    echo "Instalando Cosmic..."
    pacman -S --noconfirm noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-noto-nerd noto-fonts-extra ttf-jetbrains-mono 2>/dev/null || true
    pacman -S --noconfirm ffmpeg gst-plugins-ugly gst-plugins-good gst-plugins-base gst-plugins-bad gst-libav gstreamer 2>/dev/null || true
    pacman -S --noconfirm cosmic-session cosmic-terminal cosmic-files cosmic-store cosmic-wallpapers xdg-user-dirs croc 2>/dev/null || true
    pacman -S --noconfirm gdu 2>/dev/null || true
    systemctl enable cosmic-greeter 2>/dev/null || true
    echo "Cosmic instalado"
}

install_gnome() {
    echo "Instalando GNOME..."
    pacman -S --noconfirm noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-noto-nerd noto-fonts-extra ttf-jetbrains-mono 2>/dev/null || true
    pacman -S --noconfirm ffmpeg gst-plugins-ugly gst-plugins-good gst-plugins-base gst-plugins-bad gst-libav gstreamer 2>/dev/null || true
    pacman -S --noconfirm gnome-shell gnome-console gnome-software gnome-tweaks gnome-control-center gnome-disk-utility 2>/dev/null || true
    pacman -S --noconfirm gdm 2>/dev/null || true
    systemctl enable gdm 2>/dev/null || true
    echo "GNOME instalado"
}

install_kde() {
    echo "Instalando KDE Plasma..."
    pacman -S --noconfirm noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-noto-nerd noto-fonts-extra ttf-jetbrains-mono 2>/dev/null || true
    pacman -S --noconfirm ffmpeg gst-plugins-ugly gst-plugins-good gst-plugins-base gst-plugins-bad gst-libav gstreamer 2>/dev/null || true
    pacman -S --noconfirm plasma-meta konsole dolphin discover kdeconnect partitionmanager ffmpegthumbs dolphin-plugins 2>/dev/null || true
    pacman -S --noconfirm ark 2>/dev/null || true
    systemctl enable sddm 2>/dev/null || true
    echo "KDE Plasma instalado"
}

lazyman() {
    clear
    if [ -f "$HOME/.config/nvim-Lazyman/lazyman.sh" ]; then
        echo "Lazyman detectado"
        read -p "Desinstalar? (s/n): " -n 1 r
        echo
        [ "$r" != "s" ] && return
        
        if [ "$EUID" -ne 0 ]; then
            echo "Execute com sudo: sudo $0"
            read -p "..."
            return
        fi
        
        pacman -S --noconfirm neovim git 2>/dev/null || true
        rm -rf "$HOME/.config/nvim-Lazyman" 2>/dev/null || true
        echo "Desinstalado"
    else
        echo "Lazyman não detectado"
        read -p "Instalar? (s/n): " -n 1 r
        echo
        [ "$r" != "s" ] && return
        
        if [ "$EUID" -ne 0 ]; then
            echo "Execute com sudo: sudo $0"
            read -p "..."
            return
        fi
        
        pacman -S --noconfirm neovim git 2>/dev/null || true
        git clone --depth=1 https://github.com/doctorfree/nvim-lazyman "$HOME/.config/nvim-Lazyman" 2>/dev/null || true
        
        if [ -f "$HOME/.config/nvim-Lazyman/lazyman.sh" ]; then
            "$HOME/.config/nvim-Lazyman/lazyman.sh" -z 2>/dev/null || true
            echo "Lazyman instalado"
        else
            echo "Falha na instalação"
        fi
    fi
    read -p "..."
}

lazyvim() {
    clear
    if [ -d "$HOME/.config/nvim" ] && [ -f "$HOME/.config/nvim/init.lua" ]; then
        echo "LazyVim detectado"
        read -p "Desinstalar? (s/n): " -n 1 r
        echo
        [ "$r" != "s" ] && return
        
        rm -rf "$HOME/.config/nvim" 2>/dev/null || true
        echo "Desinstalado"
    else
        echo "LazyVim não detectado"
        read -p "Instalar? (s/n): " -n 1 r
        echo
        [ "$r" != "s" ] && return
        
        git clone https://github.com/LazyVim/starter "$HOME/.config/nvim" 2>/dev/null || true
        rm -rf "$HOME/.config/nvim/.git" 2>/dev/null || true
        
        if [ -f "$HOME/.config/nvim/init.lua" ]; then
            echo "LazyVim instalado"
        else
            echo "Falha na instalação"
        fi
    fi
    read -p "..."
}

lucidglyph() {
    clear
    if detect_lucidglyph; then
        echo "LucidGlyph detectado"
        read -p "Desinstalar? (s/n): " -n 1 r
        echo
        [ "$r" != "s" ] && return
        
        if [ "$EUID" -ne 0 ]; then
            echo "Execute com sudo para desinstalação completa"
            read -p "..."
            return
        fi
        
        if [ -f "/usr/share/lucidglyph/uninstaller.sh" ] && [ -x "/usr/share/lucidglyph/uninstaller.sh" ]; then
            /usr/share/lucidglyph/uninstaller.sh
        elif [ -f "/usr/share/freetype-envision/uninstaller.sh" ] && [ -x "/usr/share/freetype-envision/uninstaller.sh" ]; then
            /usr/share/freetype-envision/uninstaller.sh
        fi
        
        rm -rf "/usr/share/lucidglyph" 2>/dev/null || true
        rm -rf "/usr/share/freetype-envision" 2>/dev/null || true
        rm -rf "$HOME/.local/share/lucidglyph" 2>/dev/null || true
        rm -f /etc/fonts/conf.d/*lucidglyph* 2>/dev/null || true
        rm -f /etc/fonts/conf.d/*freetype-envision* 2>/dev/null || true
        rm -f "$HOME/.config/fontconfig/conf.d"/*lucidglyph* 2>/dev/null || true
        rm -f "$HOME/.config/fontconfig/conf.d"/*freetype-envision* 2>/dev/null || true
        sed -i '/LUCIDGLYPH\|FREETYPE_ENVISION/d' /etc/environment 2>/dev/null || true
        fc-cache -f 2>/dev/null || true
        
        echo "Desinstalado"
    else
        echo "LucidGlyph não detectado"
        read -p "Instalar? (s/n): " -n 1 r
        echo
        [ "$r" != "s" ] && return
        
        if [ "$EUID" -ne 0 ]; then
            echo "Execute com sudo: sudo $0"
            read -p "..."
            return
        fi
        
        tag=$(curl -s "https://api.github.com/repos/maximilionus/lucidglyph/releases/latest" 2>/dev/null | grep -oP '"tag_name": "\K(.*)(?=")' || echo "v0.11.0")
        ver="${tag#v}"
        
        cd /tmp || exit 1
        [ -f "${tag}.tar.gz" ] && rm -f "${tag}.tar.gz"
        wget -q -O "${tag}.tar.gz" "https://github.com/maximilionus/lucidglyph/archive/refs/tags/${tag}.tar.gz" || exit 1
        tar -xzf "${tag}.tar.gz" 2>/dev/null || true
        cd "lucidglyph-${ver}" 2>/dev/null || exit 1
        chmod +x lucidglyph.sh 2>/dev/null || true
        ./lucidglyph.sh install 2>/dev/null || true
        
        cd /tmp
        rm -rf "lucidglyph-${ver}" 2>/dev/null || true
        rm -f "${tag}.tar.gz" 2>/dev/null || true
        
        echo "Instalado"
    fi
    read -p "..."
}

neovim_menu() {
    clear
    echo "Configurações do Neovim:"
    echo "1) Lazyman"
    echo "2) LazyVim"
    echo "3) Voltar"
    read -p "> " o
    
    case $o in
        1) lazyman ;;
        2) lazyvim ;;
        3) return ;;
        *) echo "Opção inválida" ;;
    esac
}

oh_my_bash() {
    clear
    if [ -d "$HOME/.oh-my-bash" ]; then
        echo "Oh My Bash detectado"
        read -p "Desinstalar? (s/n): " -n 1 r
        echo
        [ "$r" != "s" ] && return
        
        yes | "$HOME/.oh-my-bash/tools/uninstall.sh" 2>/dev/null || true
        echo "Desinstalado"
    else
        echo "Oh My Bash não detectado"
        read -p "Instalar? (s/n): " -n 1 r
        echo
        [ "$r" != "s" ] && return
        
        bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" --unattended 2>/dev/null || true
        
        if [ -d "$HOME/.oh-my-bash" ]; then
            echo "Oh My Bash instalado"
        else
            echo "Falha na instalação"
        fi
    fi
    read -p "..."
}

patch_mesa() {
    cd /tmp || return 1
    wget -q https://raw.githubusercontent.com/psygreg/shader-booster/refs/heads/main/patch-mesa || return 1
    echo -e "\n$(cat /tmp/patch-mesa)" >> "${DEST_FILE}"
    rm /tmp/patch-mesa
}

patch_nv() {
    cd /tmp || return 1
    wget -q https://raw.githubusercontent.com/psygreg/shader-booster/refs/heads/main/patch-nvidia || return 1
    echo -e "\n$(cat /tmp/patch-nvidia)" >> "${DEST_FILE}"
    rm /tmp/patch-nvidia
}

remove_shader_booster() {
    sed -i '/MESA_GLSL_CACHE_DISABLE\|__GL_SHADER_DISK_CACHE_SKIP_CLEANUP\|MESA_SHADER_CACHE_DISABLE/d' "${DEST_FILE}" 2>/dev/null || true
    sed -i '/__GL_SHADER_DISK_CACHE\|__GL_SHADER_DISK_CACHE_PATH/d' "${DEST_FILE}" 2>/dev/null || true
    sed -i '/SHADER_CACHE_DISABLE\|shader-cache/d' "${DEST_FILE}" 2>/dev/null || true
    rm -f "${HOME}/.booster" 2>/dev/null || true
}

shader_booster() {
    clear
    
    if [[ -f "${HOME}/.bash_profile" ]]; then
        DEST_FILE="${HOME}/.bash_profile"
    elif [[ -f "${HOME}/.profile" ]]; then
        DEST_FILE="${HOME}/.profile"
    elif [[ -f "${HOME}/.zshrc" ]]; then
        DEST_FILE="${HOME}/.zshrc"
    else
        echo "Nenhum shell válido encontrado"
        read -p "..."
        return
    fi
    
    if [ -f "${HOME}/.booster" ]; then
        echo "Shader Booster detectado"
        read -p "Desinstalar? (s/n): " -n 1 r
        echo
        [ "$r" != "s" ] && return
        
        remove_shader_booster
        echo "Desinstalado"
    else
        echo "Shader Booster não detectado"
        read -p "Instalar? (s/n): " -n 1 r
        echo
        [ "$r" != "s" ] && return
        
        HAS_NVIDIA=$(lspci 2>/dev/null | grep -i 'nvidia' || true)
        HAS_MESA=$(lspci 2>/dev/null | grep -Ei '(vga|3d)' | grep -vi nvidia || true)
        PATCH_APPLIED=0
        
        if [[ -n "$HAS_NVIDIA" ]]; then
            patch_nv && PATCH_APPLIED=1
        fi
        
        if [[ -n "$HAS_MESA" ]]; then
            patch_mesa && PATCH_APPLIED=1
        fi

        if [ $PATCH_APPLIED -eq 1 ]; then
            echo "1" > "${HOME}/.booster"
            echo "Instalado - Reinicie para aplicar"
        else
            echo "Nenhuma GPU detectada"
        fi
    fi
    read -p "..."
}

ufw_firewall() {
    clear
    if command -v ufw &> /dev/null && systemctl is-enabled ufw 2>/dev/null | grep -q "enabled"; then
        echo "UFW detectado e ativo"
        read -p "Desinstalar? (s/n): " -n 1 r
        echo
        [ "$r" != "s" ] && return
        
        if [ "$EUID" -ne 0 ]; then
            echo "Execute com sudo: sudo $0"
            read -p "..."
            return
        fi
        
        ufw disable
        systemctl disable ufw 2>/dev/null || true
        pacman -Rns --noconfirm ufw gufw 2>/dev/null || true
        echo "Desinstalado"
    else
        echo "UFW não detectado"
        read -p "Instalar? (s/n): " -n 1 r
        echo
        [ "$r" != "s" ] && return
        
        if [ "$EUID" -ne 0 ]; then
            echo "Execute com sudo: sudo $0"
            read -p "..."
            return
        fi
        
        echo "Instalando UFW..."
        pacman -S --noconfirm ufw gufw 2>/dev/null || true
        
        if command -v ufw &> /dev/null; then
            ufw default deny incoming
            ufw default allow outgoing
            ufw allow 53317/udp
            ufw allow 53317/tcp
            ufw allow 1714:1764/udp
            ufw allow 1714:1764/tcp
            systemctl enable ufw 2>/dev/null || true
            ufw enable
        fi
        
        echo "Configurado"
    fi
    read -p "..."
}

uninstall_cosmic() {
    read -p "Desinstalar Cosmic? (s/n): " -n 1 r
    echo
    [ "$r" != "s" ] && return
    
    echo "Desinstalando Cosmic..."
    systemctl disable cosmic-greeter 2>/dev/null || true
    pacman -Rns --noconfirm cosmic-session cosmic-terminal cosmic-files cosmic-store cosmic-wallpapers 2>/dev/null || true
    echo "Cosmic desinstalado"
}

uninstall_gnome() {
    read -p "Desinstalar GNOME? (s/n): " -n 1 r
    echo
    [ "$r" != "s" ] && return
    
    echo "Desinstalando GNOME..."
    systemctl disable gdm 2>/dev/null || true
    pacman -Rns --noconfirm gnome-shell gnome-console gnome-software gnome-tweaks gnome-control-center gnome-disk-utility gdm 2>/dev/null || true
    echo "GNOME desinstalado"
}

uninstall_kde() {
    read -p "Desinstalar KDE Plasma? (s/n): " -n 1 r
    echo
    [ "$r" != "s" ] && return
    
    echo "Desinstalando KDE Plasma..."
    systemctl disable sddm 2>/dev/null || true
    pacman -Rns --noconfirm plasma-meta konsole dolphin discover kdeconnect partitionmanager ffmpegthumbs dolphin-plugins ark 2>/dev/null || true
    echo "KDE Plasma desinstalado"
}

main
