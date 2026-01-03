#!/bin/bash
set -e

[ ! -f /etc/arch-release ] && echo "Este script é exclusivo para Arch Linux" && exit 1

if [ "$EUID" -ne 0 ] && ! grep -q 'arch-chroot' /proc/1/cmdline 2>/dev/null; then
    echo "Execute com sudo: sudo $0"
    exit 1
fi

S_SHADER="$HOME/.booster_state"
S_DE="$HOME/.de_state"
S_LUCID="$HOME/.lucidglyph_state"
S_APPARMOR="$HOME/.apparmor_state"
S_UFW="$HOME/.ufw_state"
S_EARLYOOM="$HOME/.earlyoom_state"
S_DNSMASQ="$HOME/.dnsmasq_state"
S_NIX="$HOME/.nix_state"
S_CHAOTIC="$HOME/.chaotic_state"
S_DOCKER="$HOME/.docker_state"
S_TAILSCALE="$HOME/.tailscale_state"
S_FISHER="$HOME/.fisher_state"
S_STARSHIP="$HOME/.starship_state"
S_OHMYBASH="$HOME/.ohmybash_state"
S_FLATHUB="$HOME/.flathub_state"
S_YAY="$HOME/.yay_state"
S_LAZYMAN="$HOME/.lazyman_state"
S_ONDEMAND="$HOME/.ondemand_state"
S_ANANICY="$HOME/.ananicy_state"
S_ARCHSB="$HOME/.archsb_state"
S_BTRFS="$HOME/.btrfs_state"
S_CACHYCONFS="$HOME/.cachyconfs_state"
S_HWACCEL_FLATPAK="$HOME/.hwaccel_flatpak_state"
S_SWAPFILE="$HOME/.swapfile_state"
S_DISTROBOX_HANDLER="$HOME/.distrobox_handler_state"

shader_booster() {
    clear
    echo "=== Shader Booster ==="
    
    if [ -f "$S_SHADER" ]; then
        echo "Status: ATIVO"
        echo "1) Desativar"
        echo "2) Ver status"
        echo "3) Voltar"
        read -p "> " opt
        
        case $opt in
            1)
                for shell_file in "${HOME}/.bash_profile" "${HOME}/.profile" "${HOME}/.zshrc"; do
                    if [ -f "$shell_file" ]; then
                        sed -i '/# shader-booster-nvidia/,/^$/d' "$shell_file" 2>/dev/null
                        sed -i '/# shader-booster-mesa/,/^$/d' "$shell_file" 2>/dev/null
                    fi
                done
                rm -f "$S_SHADER"
                echo "Desativado. Reinicie para aplicar."
                ;;
            2)
                if [ -f "$S_SHADER" ]; then
                    echo "Shader Booster ativo desde: $(date -r "$S_SHADER")"
                fi
                ;;
            3)
                return
                ;;
        esac
    else
        echo "Status: INATIVO"
        read -p "Ativar Shader Booster? (s/n): " -n 1 resposta
        echo
        
        if [ "$resposta" = "s" ]; then
            if [[ -f "${HOME}/.bash_profile" ]]; then
                DEST_FILE="${HOME}/.bash_profile"
            elif [[ -f "${HOME}/.profile" ]]; then
                DEST_FILE="${HOME}/.profile"
            elif [[ -f "${HOME}/.zshrc" ]]; then
                DEST_FILE="${HOME}/.zshrc"
            else
                echo "Erro: Nenhum arquivo de shell encontrado"
                read -p "Pressione Enter para continuar..."
                return
            fi
            
            PATCH_APPLIED=0
            
            if lspci | grep -qi 'nvidia'; then
                echo "Aplicando patch para NVIDIA..."
                curl -s https://raw.githubusercontent.com/psygreg/shader-booster/main/patch-nvidia -o /tmp/patch-nvidia
                if [ -s /tmp/patch-nvidia ]; then
                    echo "" >> "$DEST_FILE"
                    cat /tmp/patch-nvidia >> "$DEST_FILE"
                    PATCH_APPLIED=1
                fi
                rm -f /tmp/patch-nvidia
            fi
            
            if lspci | grep -Ei '(vga|3d)' | grep -qvi nvidia; then
                echo "Aplicando patch para Mesa..."
                curl -s https://raw.githubusercontent.com/psygreg/shader-booster/main/patch-mesa -o /tmp/patch-mesa
                if [ -s /tmp/patch-mesa ]; then
                    echo "" >> "$DEST_FILE"
                    cat /tmp/patch-mesa >> "$DEST_FILE"
                    PATCH_APPLIED=1
                fi
                rm -f /tmp/patch-mesa
            fi
            
            if [ $PATCH_APPLIED -eq 1 ]; then
                echo "1" > "$S_SHADER"
                echo "Sucesso! Reinicie para aplicar."
            else
                echo "Nenhuma GPU compatível detectada."
            fi
        fi
    fi
    
    read -p "Pressione Enter para continuar..."
}

install_cosmic() {
    clear
    echo "=== Instalando Cosmic Desktop ==="
    
    pacman -Syu --noconfirm
    pacman -S --noconfirm noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-noto-nerd noto-fonts-extra ttf-jetbrains-mono
    pacman -S --noconfirm ffmpeg gst-plugins-ugly gst-plugins-good gst-plugins-base gst-plugins-bad gst-libav gstreamer
    pacman -S --noconfirm gdu nvidia-open intel-ucode git neovim fastfetch btop ufw fwupd flatpak yt-dlp aria2 tealdeer
    pacman -S --noconfirm cosmic-session cosmic-terminal cosmic-files cosmic-store cosmic-wallpapers xdg-user-dirs croc
    
    systemctl enable cosmic-greeter
    
    echo "Cosmic Desktop instalado com sucesso!"
    echo "cosmic" > "$S_DE"
    read -p "Pressione Enter para continuar..."
}

install_gnome() {
    clear
    echo "=== Instalando GNOME Desktop ==="
    
    pacman -Syu --noconfirm
    pacman -S --noconfirm noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-noto-nerd noto-fonts-extra ttf-jetbrains-mono
    pacman -S --noconfirm ffmpeg gst-plugins-ugly gst-plugins-good gst-plugins-base gst-plugins-bad gst-libav gstreamer
    pacman -S --noconfirm gnome-shell gnome-console gnome-software gnome-tweaks gnome-control-center gnome-disk-utility
    pacman -S --noconfirm gdm nvidia-open intel-ucode git neovim fastfetch btop ufw fwupd flatpak yt-dlp aria2 tealdeer
    
    systemctl enable gdm
    
    echo "GNOME Desktop instalado com sucesso!"
    echo "gnome" > "$S_DE"
    read -p "Pressione Enter para continuar..."
}

install_kde() {
    clear
    echo "=== Instalando KDE Plasma ==="
    
    pacman -Syu --noconfirm
    pacman -S --noconfirm noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-noto-nerd noto-fonts-extra ttf-jetbrains-mono
    pacman -S --noconfirm ffmpeg gst-plugins-ugly gst-plugins-good gst-plugins-base gst-plugins-bad gst-libav gstreamer
    pacman -S --noconfirm ark nvidia-open intel-ucode git neovim fastfetch btop ufw fwupd flatpak yt-dlp aria2 tealdeer
    pacman -S --noconfirm plasma-meta konsole dolphin discover kdeconnect partitionmanager ffmpegthumbs dolphin-plugins
    
    systemctl enable sddm
    
    echo "KDE Plasma instalado com sucesso!"
    echo "kde" > "$S_DE"
    read -p "Pressione Enter para continuar..."
}

desktop_environment() {
    clear
    echo "=== Desktop Environment ==="
    
    if [ -f "$S_DE" ]; then
        de_status=$(cat "$S_DE")
        case $de_status in
            cosmic) echo "Status: Cosmic Desktop instalado" ;;
            gnome) echo "Status: GNOME Desktop instalado" ;;
            kde) echo "Status: KDE Plasma instalado" ;;
        esac
        
        echo "1) Instalar Cosmic Desktop"
        echo "2) Instalar GNOME Desktop"
        echo "3) Instalar KDE Plasma"
        echo "4) Remover status"
        echo "5) Voltar"
        read -p "> " opt
        
        case $opt in
            1) install_cosmic ;;
            2) install_gnome ;;
            3) install_kde ;;
            4)
                rm -f "$S_DE"
                echo "Status removido."
                read -p "Pressione Enter para continuar..."
                ;;
            5) return ;;
            *) ;;
        esac
    else
        echo "Status: Nenhum DE instalado via este script"
        echo "1) Instalar Cosmic Desktop"
        echo "2) Instalar GNOME Desktop"
        echo "3) Instalar KDE Plasma"
        echo "4) Voltar"
        read -p "> " opt
        
        case $opt in
            1) install_cosmic ;;
            2) install_gnome ;;
            3) install_kde ;;
            4) return ;;
            *) ;;
        esac
    fi
}

detect_lucidglyph() {
    if [ -f "/usr/share/lucidglyph/info" ] || [ -f "/usr/share/freetype-envision/info" ]; then
        return 0
    fi
    if [ -f "$HOME/.local/share/lucidglyph/info" ]; then
        return 0
    fi
    if [ -d "/etc/fonts/conf.d" ] && find "/etc/fonts/conf.d" -name "*lucidglyph*" -o -name "*freetype-envision*" 2>/dev/null | grep -q .; then
        return 0
    fi
    if [ -d "$HOME/.config/fontconfig/conf.d" ] && find "$HOME/.config/fontconfig/conf.d" -name "*lucidglyph*" -o -name "*freetype-envision*" 2>/dev/null | grep -q .; then
        return 0
    fi
    if [ -f "/etc/environment" ] && grep -q "LUCIDGLYPH\|FREETYPE_ENVISION" "/etc/environment" 2>/dev/null; then
        return 0
    fi
    return 1
}

uninstall_lucidglyph() {
    echo "Removendo arquivos do LucidGlyph..."
    
    rm -rf /usr/share/lucidglyph /usr/share/freetype-envision 2>/dev/null
    rm -rf /usr/local/share/lucidglyph /usr/local/share/freetype-envision 2>/dev/null
    
    rm -rf "$HOME/.local/share/lucidglyph" "$HOME/.local/share/freetype-envision" 2>/dev/null
    
    find /etc/fonts/conf.d -name "*lucidglyph*" -o -name "*freetype-envision*" 2>/dev/null | xargs rm -f
    find "$HOME/.config/fontconfig/conf.d" -name "*lucidglyph*" -o -name "*freetype-envision*" 2>/dev/null | xargs rm -f
    
    sed -i '/LUCIDGLYPH\|FREETYPE_ENVISION/d' /etc/environment 2>/dev/null
    sed -i '/LUCIDGLYPH\|FREETYPE_ENVISION/d' "$HOME/.profile" 2>/dev/null
    sed -i '/LUCIDGLYPH\|FREETYPE_ENVISION/d' "$HOME/.bashrc" 2>/dev/null
    sed -i '/LUCIDGLYPH\|FREETYPE_ENVISION/d' "$HOME/.zshrc" 2>/dev/null
    
    echo "LucidGlyph removido do sistema."
}

lucidglyph() {
    clear
    echo "=== LucidGlyph ==="
    
    if detect_lucidglyph; then
        echo "LucidGlyph já está instalado no sistema."
        echo "1) Desinstalar"
        echo "2) Verificar status"
        echo "3) Voltar"
        read -p "> " opt
        
        case $opt in
            1)
                read -p "Deseja desinstalar o LucidGlyph? (s/n): " -n 1 resposta
                echo
                if [ "$resposta" = "s" ]; then
                    uninstall_lucidglyph
                    rm -f "$S_LUCID"
                    echo "LucidGlyph desinstalado com sucesso."
                fi
                ;;
            2)
                if [ -f "$S_LUCID" ]; then
                    echo "LucidGlyph instalado via este script desde: $(date -r "$S_LUCID")"
                else
                    echo "LucidGlyph detectado no sistema (não instalado via este script)"
                fi
                ;;
            3)
                return
                ;;
        esac
    else
        echo "Status: Não instalado"
        read -p "Instalar LucidGlyph? (s/n): " -n 1 resposta
        echo
        
        if [ "$resposta" = "s" ]; then
            echo "Baixando e instalando LucidGlyph..."
            
            tag=$(curl -s "https://api.github.com/repos/maximilionus/lucidglyph/releases/latest" | grep -oP '"tag_name": "\K(.*)(?=")' || echo "v0.11.0")
            ver="${tag#v}"
            
            cd "$HOME" || exit 1
            [ -f "${tag}.tar.gz" ] && rm -f "${tag}.tar.gz"
            
            wget -O "${tag}.tar.gz" "https://github.com/maximilionus/lucidglyph/archive/refs/tags/${tag}.tar.gz"
            tar -xvzf "${tag}.tar.gz"
            
            cd "lucidglyph-${ver}" || exit 1
            chmod +x lucidglyph.sh
            
            ./lucidglyph.sh install
            
            cd ..
            sleep 1
            rm -rf "lucidglyph-${ver}"
            rm -f "${tag}.tar.gz"
            
            echo "1" > "$S_LUCID"
            echo "LucidGlyph instalado com sucesso!"
        fi
    fi
    
    read -p "Pressione Enter para continuar..."
}

apparmor() {
    clear
    echo "=== AppArmor ==="
    
    if [ -f "$S_APPARMOR" ]; then
        echo "Status: INSTALADO"
        echo "1) Desinstalar"
        echo "2) Ver status"
        echo "3) Voltar"
        read -p "> " opt
        
        case $opt in
            1)
                read -p "Deseja remover o AppArmor? (s/n): " -n 1 resposta
                echo
                if [ "$resposta" = "s" ]; then
                    if [ -f "/etc/default/grub.d/99-apparmor.cfg" ]; then
                        rm -f /etc/default/grub.d/99-apparmor.cfg
                        grub-mkconfig -o /boot/grub/grub.cfg
                    fi
                    
                    if [ -d "/etc/kernel/cmdline.d" ]; then
                        rm -f /etc/kernel/cmdline.d/99-apparmor.conf 2>/dev/null
                        bootctl update 2>/dev/null || true
                    fi
                    
                    systemctl disable apparmor --now 2>/dev/null
                    pacman -Rns --noconfirm apparmor
                    
                    rm -f "$S_APPARMOR"
                    echo "AppArmor removido. Reinicie para aplicar."
                fi
                ;;
            2)
                if [ -f "$S_APPARMOR" ]; then
                    echo "AppArmor instalado via este script desde: $(date -r "$S_APPARMOR")"
                    
                    if systemctl is-active apparmor &>/dev/null; then
                        echo "Serviço: ATIVO"
                    else
                        echo "Serviço: INATIVO"
                    fi
                fi
                ;;
            3)
                return
                ;;
        esac
    else
        echo "Status: NÃO INSTALADO"
        read -p "Instalar AppArmor? (s/n): " -n 1 resposta
        echo
        
        if [ "$resposta" = "s" ]; then
            echo "Instalando AppArmor..."
            
            pacman -S --noconfirm apparmor
            
            if pacman -Qi grub &>/dev/null; then
                mkdir -p /etc/default/grub.d
                echo 'GRUB_CMDLINE_LINUX_DEFAULT="${GRUB_CMDLINE_LINUX_DEFAULT} apparmor=1 security=apparmor"' | tee /etc/default/grub.d/99-apparmor.cfg
                grub-mkconfig -o /boot/grub/grub.cfg
            else
                mkdir -p /etc/kernel/cmdline.d 2>/dev/null || true
                echo "apparmor=1 security=apparmor" | tee /etc/kernel/cmdline.d/99-apparmor.conf 2>/dev/null
                bootctl update 2>/dev/null || true
            fi
            
            systemctl enable apparmor
            
            echo "1" > "$S_APPARMOR"
            echo "AppArmor instalado com sucesso! Reinicie para aplicar."
        fi
    fi
    
    read -p "Pressione Enter para continuar..."
}

ufw_firewall() {
    clear
    echo "=== UFW Firewall ==="
    
    if [ -f "$S_UFW" ]; then
        echo "Status: INSTALADO E ATIVO"
        echo "1) Desinstalar"
        echo "2) Ver status"
        echo "3) Reiniciar UFW"
        echo "4) Ver regras"
        echo "5) Voltar"
        read -p "> " opt
        
        case $opt in
            1)
                read -p "Deseja remover o UFW? (s/n): " -n 1 resposta
                echo
                if [ "$resposta" = "s" ]; then
                    ufw disable
                    systemctl disable ufw --now 2>/dev/null
                    pacman -Rns --noconfirm ufw gufw
                    rm -f "$S_UFW"
                    echo "UFW removido."
                fi
                ;;
            2)
                if [ -f "$S_UFW" ]; then
                    echo "UFW instalado via este script desde: $(date -r "$S_UFW")"
                    echo ""
                    ufw status verbose
                fi
                ;;
            3)
                ufw disable
                ufw enable
                echo "UFW reiniciado."
                ;;
            4)
                ufw status numbered
                ;;
            5)
                return
                ;;
        esac
    else
        echo "Status: NÃO INSTALADO"
        read -p "Instalar e configurar UFW? (s/n): " -n 1 resposta
        echo
        
        if [ "$resposta" = "s" ]; then
            echo "Instalando UFW..."
            
            pacman -S --noconfirm ufw gufw
            
            ufw default deny incoming
            ufw default allow outgoing
            
            systemctl enable ufw
            ufw enable
            
            ufw allow 53317/udp
            ufw allow 53317/tcp
            ufw allow 1714:1764/udp
            ufw allow 1714:1764/tcp
            
            echo "1" > "$S_UFW"
            echo "UFW instalado e configurado com sucesso!"
            echo ""
            ufw status verbose
        fi
    fi
    
    read -p "Pressione Enter para continuar..."
}

earlyoom() {
    clear
    echo "=== EarlyOOM ==="
    
    if [ -f "$S_EARLYOOM" ]; then
        echo "Status: INSTALADO"
        echo "1) Desinstalar"
        echo "2) Ver status"
        echo "3) Reiniciar serviço"
        echo "4) Voltar"
        read -p "> " opt
        
        case $opt in
            1)
                read -p "Deseja remover o EarlyOOM? (s/n): " -n 1 resposta
                echo
                if [ "$resposta" = "s" ]; then
                    systemctl disable earlyoom --now 2>/dev/null
                    pacman -Rns --noconfirm earlyoom
                    rm -f "$S_EARLYOOM"
                    echo "EarlyOOM removido."
                fi
                ;;
            2)
                if [ -f "$S_EARLYOOM" ]; then
                    echo "EarlyOOM instalado via este script desde: $(date -r "$S_EARLYOOM")"
                    
                    if systemctl is-active earlyoom &>/dev/null; then
                        echo "Serviço: ATIVO"
                        echo "Status do processo:"
                        earlyoom --version
                    else
                        echo "Serviço: INATIVO"
                    fi
                fi
                ;;
            3)
                systemctl restart earlyoom
                echo "Serviço EarlyOOM reiniciado."
                ;;
            4)
                return
                ;;
        esac
    else
        echo "Status: NÃO INSTALADO"
        read -p "Instalar EarlyOOM? (s/n): " -n 1 resposta
        echo
        
        if [ "$resposta" = "s" ]; then
            echo "Instalando EarlyOOM..."
            
            pacman -S --noconfirm earlyoom
            systemctl enable earlyoom
            systemctl start earlyoom
            
            echo "1" > "$S_EARLYOOM"
            echo "EarlyOOM instalado e ativado com sucesso!"
        fi
    fi
    
    read -p "Pressione Enter para continuar..."
}

dnsmasq() {
    clear
    echo "=== DNSMasq ==="
    
    if [ -f "$S_DNSMASQ" ]; then
        echo "Status: INSTALADO"
        echo "1) Desinstalar"
        echo "2) Ver status"
        echo "3) Reiniciar serviço"
        echo "4) Voltar"
        read -p "> " opt
        
        case $opt in
            1)
                read -p "Deseja remover o DNSMasq? (s/n): " -n 1 resposta
                echo
                if [ "$resposta" = "s" ]; then
                    systemctl disable dnsmasq --now 2>/dev/null
                    pacman -Rns --noconfirm dnsmasq
                    rm -f "$S_DNSMASQ"
                    echo "DNSMasq removido."
                fi
                ;;
            2)
                if [ -f "$S_DNSMASQ" ]; then
                    echo "DNSMasq instalado via este script desde: $(date -r "$S_DNSMASQ")"
                    
                    if systemctl is-active dnsmasq &>/dev/null; then
                        echo "Serviço: ATIVO"
                        echo "Configuração:"
                        cat /etc/dnsmasq.conf 2>/dev/null | head -20
                    else
                        echo "Serviço: INATIVO"
                    fi
                fi
                ;;
            3)
                systemctl restart dnsmasq
                echo "Serviço DNSMasq reiniciado."
                ;;
            4)
                return
                ;;
        esac
    else
        echo "Status: NÃO INSTALADO"
        read -p "Instalar DNSMasq? (s/n): " -n 1 resposta
        echo
        
        if [ "$resposta" = "s" ]; then
            echo "Instalando DNSMasq..."
            
            pacman -S --noconfirm dnsmasq
            
            cat > /etc/dnsmasq.conf << 'EOF'
port=53
domain-needed
bogus-priv
no-resolv
server=8.8.8.8
server=8.8.4.4
cache-size=1000
local-ttl=300
EOF
            
            systemctl enable dnsmasq
            systemctl start dnsmasq
            
            echo "1" > "$S_DNSMASQ"
            echo "DNSMasq instalado e configurado com sucesso! Reinicie para aplicar."
        fi
    fi
    
    read -p "Pressione Enter para continuar..."
}

nix_packages() {
    clear
    echo "=== Nix Packages ==="
    
    if [ -f "$S_NIX" ]; then
        echo "Status: INSTALADO"
        echo "1) Desinstalar"
        echo "2) Ver status"
        echo "3) Verificar instalação"
        echo "4) Voltar"
        read -p "> " opt
        
        case $opt in
            1)
                read -p "Deseja remover o Nix? (s/n): " -n 1 resposta
                echo
                if [ "$resposta" = "s" ]; then
                    echo "Desinstalando Nix..."
                    
                    if pacman -Qi nix 2>/dev/null | grep -q "Name"; then
                        pacman -Rns --noconfirm nix 2>/dev/null
                    fi
                    
                    sed -i '/export PATH="\$HOME\/.nix-profile\/bin:\$PATH"/d' ~/.bashrc 2>/dev/null
                    sed -i '/export XDG_DATA_DIRS="\$HOME\/.nix-profile\/share:\$XDG_DATA_DIRS"/d' ~/.profile 2>/dev/null
                    sed -i '/export XDG_DATA_DIRS="\$HOME\/.nix-profile\/share:\$XDG_DATA_DIRS"/d' ~/.bash_profile 2>/dev/null
                    sed -i '/source \${\?HOME\}\?\/.nix-profile\/etc\/profile.d\/nix.sh/d' ~/.bashrc 2>/dev/null
                    
                    rm -rf ~/.nix-profile ~/.nix-defexpr ~/.nix-channels ~/.config/nix /nix 2>/dev/null
                    
                    rm -f "$S_NIX"
                    echo "Nix removido. Reinicie o shell para aplicar."
                fi
                ;;
            2)
                if [ -f "$S_NIX" ]; then
                    echo "Nix instalado via este script desde: $(date -r "$S_NIX")"
                    
                    if pacman -Qi nix 2>/dev/null | grep -q "Name" || command -v nix &>/dev/null; then
                        echo "Nix está instalado no sistema."
                        if command -v nix &>/dev/null; then
                            nix --version
                        else
                            echo "(Instalado via pacman, mas nix não está no PATH atual)"
                        fi
                    else
                        echo "Nix não está instalado."
                    fi
                fi
                ;;
            3)
                if pacman -Qi nix 2>/dev/null | grep -q "Name" || command -v nix &>/dev/null; then
                    echo "Nix está instalado no sistema."
                    if command -v nix &>/dev/null; then
                        nix --version
                    else
                        echo "Pacote nix instalado via pacman."
                    fi
                else
                    echo "Nix não está instalado no sistema."
                fi
                ;;
            4)
                return
                ;;
        esac
    else
        echo "Status: NÃO INSTALADO"
        read -p "Instalar Nix Packages? (s/n): " -n 1 resposta
        echo
        
        if [ "$resposta" = "s" ]; then
            echo "Instalando Nix Packages..."
            
            pacman -S --noconfirm nix
            
            if [ -f ~/.bashrc ]; then
                echo 'export PATH="$HOME/.nix-profile/bin:$PATH"' >> ~/.bashrc
            fi
            
            if [ -f ~/.profile ]; then
                echo 'export XDG_DATA_DIRS="$HOME/.nix-profile/share:$XDG_DATA_DIRS"' >> ~/.profile
            fi
            
            if [ -f ~/.bash_profile ]; then
                echo 'export XDG_DATA_DIRS="$HOME/.nix-profile/share:$XDG_DATA_DIRS"' >> ~/.bash_profile
            fi
            
            echo "1" > "$S_NIX"
            echo "Nix Packages instalado com sucesso! Reinicie o shell para aplicar."
        fi
    fi
    
    read -p "Pressione Enter para continuar..."
}

chaotic_aur() {
    clear
    echo "=== Chaotic AUR ==="
    
    if [ -f "$S_CHAOTIC" ]; then
        echo "Status: INSTALADO"
        echo "1) Desinstalar"
        echo "2) Ver status"
        echo "3) Atualizar pacotes Chaotic"
        echo "4) Voltar"
        read -p "> " opt
        
        case $opt in
            1)
                read -p "Deseja remover o Chaotic AUR? (s/n): " -n 1 resposta
                echo
                if [ "$resposta" = "s" ]; then
                    sed -i '/\[chaotic-aur\]/,+2d' /etc/pacman.conf
                    
                    pacman -Rns --noconfirm chaotic-keyring chaotic-mirrorlist 2>/dev/null || true
                    
                    sed -i '/ILoveCandy/d' /etc/pacman.conf
                    sed -i '/ParallelDownloads = 15/d' /etc/pacman.conf
                    
                    rm -f "$S_CHAOTIC"
                    echo "Chaotic AUR removido. Execute 'pacman -Syu' para atualizar."
                fi
                ;;
            2)
                if [ -f "$S_CHAOTIC" ]; then
                    echo "Chaotic AUR instalado via este script desde: $(date -r "$S_CHAOTIC")"
                    
                    if grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
                        echo "Repositório: CONFIGURADO"
                    else
                        echo "Repositório: NÃO CONFIGURADO"
                    fi
                fi
                ;;
            3)
                pacman -Syu --noconfirm
                echo "Pacotes atualizados."
                ;;
            4)
                return
                ;;
        esac
    else
        echo "Status: NÃO INSTALADO"
        read -p "Instalar Chaotic AUR? (s/n): " -n 1 resposta
        echo
        
        if [ "$resposta" = "s" ]; then
            echo "Instalando Chaotic AUR..."
            
            pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
            pacman-key --lsign-key 3056513887B78AEB
            
            pacman -U --noconfirm "https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst"
            pacman -U --noconfirm "https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst"
            
            sed -i 's/^#Color/Color/' /etc/pacman.conf
            sed -i '/Color/a ILoveCandy' /etc/pacman.conf
            sed -i '/^ParallelDownloads/d' /etc/pacman.conf
            sed -i '/ILoveCandy/a ParallelDownloads = 15' /etc/pacman.conf
            
            echo -e "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" | tee -a /etc/pacman.conf
            
            pacman -Syu --noconfirm
            
            echo "1" > "$S_CHAOTIC"
            echo "Chaotic AUR instalado e configurado com sucesso!"
        fi
    fi
    
    read -p "Pressione Enter para continuar..."
}

docker_install() {
    clear
    echo "=== Docker ==="
    
    if [ -f "$S_DOCKER" ]; then
        echo "Status: INSTALADO"
        echo "1) Desinstalar"
        echo "2) Ver status"
        echo "3) Reiniciar serviço"
        echo "4) Verificar instalação"
        echo "5) Voltar"
        read -p "> " opt
        
        case $opt in
            1)
                read -p "Deseja remover o Docker? (s/n): " -n 1 resposta
                echo
                if [ "$resposta" = "s" ]; then
                    systemctl disable docker --now 2>/dev/null
                    systemctl disable docker.socket --now 2>/dev/null
                    
                    pacman -Rns --noconfirm docker docker-compose docker-buildx docker-rootless-extras
                    
                    if getent group docker >/dev/null; then
                        gpasswd -d $USER docker 2>/dev/null || true
                    fi
                    
                    rm -f "$S_DOCKER"
                    echo "Docker removido. Reinicie para aplicar."
                fi
                ;;
            2)
                if [ -f "$S_DOCKER" ]; then
                    echo "Docker instalado via este script desde: $(date -r "$S_DOCKER")"
                    
                    if systemctl is-active docker &>/dev/null; then
                        echo "Serviço Docker: ATIVO"
                    else
                        echo "Serviço Docker: INATIVO"
                    fi
                    
                    if command -v docker &>/dev/null; then
                        echo "Versão do Docker:"
                        docker --version
                    fi
                fi
                ;;
            3)
                systemctl restart docker
                echo "Serviço Docker reiniciado."
                ;;
            4)
                if command -v docker &>/dev/null; then
                    echo "Docker está instalado no sistema."
                    docker --version
                    echo ""
                    echo "Status do serviço:"
                    systemctl status docker --no-pager | head -5
                else
                    echo "Docker não está instalado no sistema."
                fi
                ;;
            5)
                return
                ;;
        esac
    else
        echo "Status: NÃO INSTALADO"
        read -p "Instalar Docker? (s/n): " -n 1 resposta
        echo
        
        if [ "$resposta" = "s" ]; then
            echo "Instalando Docker..."
            
            pacman -Syu --noconfirm
            
            pacman -S --noconfirm docker docker-compose docker-buildx docker-rootless-extras
            
            usermod -aG docker $USER
            
            systemctl enable docker
            systemctl enable docker.socket
            systemctl start docker
            systemctl start docker.socket
            
            sleep 2
            
            echo "1" > "$S_DOCKER"
            echo "Docker instalado com sucesso! Reinicie para que o usuário seja adicionado ao grupo docker."
            echo ""
            echo "Pode instalar o Portainer CE para gerenciar o Docker após reiniciar."
        fi
    fi
    
    read -p "Pressione Enter para continuar..."
}

tailscale_install() {
    clear
    echo "=== Tailscale ==="
    
    if [ -f "$S_TAILSCALE" ]; then
        echo "Status: INSTALADO"
        echo "1) Desinstalar"
        echo "2) Ver status"
        echo "3) Reiniciar serviço"
        echo "4) Conectar ao Tailscale"
        echo "5) Desconectar"
        echo "6) Voltar"
        read -p "> " opt
        
        case $opt in
            1)
                read -p "Deseja remover o Tailscale? (s/n): " -n 1 resposta
                echo
                if [ "$resposta" = "s" ]; then
                    systemctl disable tailscaled --now 2>/dev/null
                    
                    if command -v tailscale &>/dev/null; then
                        tailscale down 2>/dev/null || true
                    fi
                    
                    pacman -Rns --noconfirm tailscale
                    
                    rm -f "$S_TAILSCALE"
                    echo "Tailscale removido."
                fi
                ;;
            2)
                if [ -f "$S_TAILSCALE" ]; then
                    echo "Tailscale instalado via este script desde: $(date -r "$S_TAILSCALE")"
                    
                    if systemctl is-active tailscaled &>/dev/null; then
                        echo "Serviço: ATIVO"
                    else
                        echo "Serviço: INATIVO"
                    fi
                    
                    if command -v tailscale &>/dev/null; then
                        echo "Status da conexão:"
                        tailscale status 2>/dev/null || echo "Não conectado"
                    fi
                fi
                ;;
            3)
                systemctl restart tailscaled
                echo "Serviço Tailscale reiniciado."
                ;;
            4)
                if command -v tailscale &>/dev/null; then
                    echo "Iniciando conexão ao Tailscale..."
                    echo "Siga as instruções no navegador que será aberto."
                    tailscale up
                else
                    echo "Tailscale não está instalado."
                fi
                ;;
            5)
                if command -v tailscale &>/dev/null; then
                    tailscale down
                    echo "Desconectado do Tailscale."
                fi
                ;;
            6)
                return
                ;;
        esac
    else
        echo "Status: NÃO INSTALADO"
        read -p "Instalar Tailscale? (s/n): " -n 1 resposta
        echo
        
        if [ "$resposta" = "s" ]; then
            echo "Instalando Tailscale..."
            
            pacman -S --noconfirm tailscale
            
            systemctl enable tailscaled
            systemctl start tailscaled
            
            echo "1" > "$S_TAILSCALE"
            echo "Tailscale instalado com sucesso!"
            echo ""
            echo "Para conectar, execute:"
            echo "tailscale up"
            echo ""
            echo "Ou selecione a opção 'Conectar ao Tailscale' no menu."
        fi
    fi
    
    read -p "Pressione Enter para continuar..."
}

fisher_install() {
    clear
    echo "=== Fisher (Fish Shell + Fisher) ==="
    
    if [ -f "$S_FISHER" ]; then
        echo "Status: INSTALADO"
        echo "1) Desinstalar"
        echo "2) Ver status"
        echo "3) Alterar shell padrão"
        echo "4) Voltar"
        read -p "> " opt
        
        case $opt in
            1)
                read -p "Deseja remover o Fisher e Fish Shell? (s/n): " -n 1 resposta
                echo
                if [ "$resposta" = "s" ]; then
                    chsh -s /bin/bash $USER
                    
                    rm -rf ~/.config/fish
                    
                    pacman -Rns --noconfirm fish fisher
                    
                    rm -f "$S_FISHER"
                    echo "Fisher e Fish Shell removidos. Reinicie o terminal para aplicar."
                fi
                ;;
            2)
                if [ -f "$S_FISHER" ]; then
                    echo "Fisher instalado via este script desde: $(date -r "$S_FISHER")"
                    
                    if command -v fish &>/dev/null; then
                        echo "Fish Shell está instalado."
                        fish --version
                        
                        if command -v fisher &>/dev/null; then
                            echo "Fisher está instalado."
                        else
                            echo "Fisher NÃO está instalado."
                        fi
                        
                        current_shell=$(getent passwd $USER | cut -d: -f7)
                        if [ "$current_shell" = "$(which fish)" ]; then
                            echo "Fish é o shell padrão."
                        else
                            echo "Fish NÃO é o shell padrão."
                            echo "Shell atual: $current_shell"
                        fi
                    else
                        echo "Fish Shell não está instalado."
                    fi
                fi
                ;;
            3)
                if command -v fish &>/dev/null; then
                    read -p "Deseja alterar o shell padrão para Fish? (s/n): " -n 1 resposta
                    echo
                    if [ "$resposta" = "s" ]; then
                        chsh -s "$(which fish)" $USER
                        echo "Shell padrão alterado para Fish. Reinicie o terminal para aplicar."
                    fi
                else
                    echo "Fish Shell não está instalado."
                fi
                ;;
            4)
                return
                ;;
        esac
    else
        echo "Status: NÃO INSTALADO"
        read -p "Instalar Fish Shell e Fisher? (s/n): " -n 1 resposta
        echo
        
        if [ "$resposta" = "s" ]; then
            echo "Instalando Fish Shell e Fisher..."
            
            pacman -S --noconfirm fish fisher
            
            echo "Configurando Fish como shell padrão..."
            chsh -s "$(which fish)" $USER
            
            echo "1" > "$S_FISHER"
            echo "Fish Shell e Fisher instalados com sucesso!"
            echo ""
            echo "O Fish Shell foi configurado como shell padrão."
            echo "Reinicie o terminal para começar a usar."
        fi
    fi
    
    read -p "Pressione Enter para continuar..."
}

starship_install() {
    clear
    echo "=== Starship Prompt ==="
    
    if [ -f "$S_STARSHIP" ]; then
        echo "Status: INSTALADO"
        echo "1) Desinstalar"
        echo "2) Ver status"
        echo "3) Configurar para shells"
        echo "4) Voltar"
        read -p "> " opt
        
        case $opt in
            1)
                read -p "Deseja remover o Starship? (s/n): " -n 1 resposta
                echo
                if [ "$resposta" = "s" ]; then
                    echo "Desinstalando Starship..."
                    
                    if pacman -Qi starship 2>/dev/null | grep -q "Name"; then
                        pacman -Rns --noconfirm starship 2>/dev/null
                    fi
                    
                    rm -f /usr/local/bin/starship 2>/dev/null
                    rm -f /usr/bin/starship 2>/dev/null
                    
                    sed -i '/eval "\$(starship init bash)"/d' ~/.bashrc 2>/dev/null
                    sed -i '/eval "\$(starship init zsh)"/d' ~/.zshrc 2>/dev/null
                    
                    if [ -f ~/.config/fish/config.fish ]; then
                        sed -i '/starship init fish | source/d' ~/.config/fish/config.fish 2>/dev/null
                    fi
                    
                    rm -f "$S_STARSHIP"
                    echo "Starship removido. Reinicie os terminais para aplicar."
                fi
                ;;
            2)
                if [ -f "$S_STARSHIP" ]; then
                    echo "Starship instalado via este script desde: $(date -r "$S_STARSHIP")"
                    
                    if command -v starship &>/dev/null; then
                        echo "Starship está instalado."
                        starship --version
                        
                        echo ""
                        echo "Configurações ativas:"
                        
                        if grep -q 'eval "\$(starship init bash)"' ~/.bashrc 2>/dev/null; then
                            echo "- Bash: CONFIGURADO"
                        else
                            echo "- Bash: NÃO CONFIGURADO"
                        fi
                        
                        if grep -q 'eval "\$(starship init zsh)"' ~/.zshrc 2>/dev/null; then
                            echo "- Zsh: CONFIGURADO"
                        else
                            echo "- Zsh: NÃO CONFIGURADO"
                        fi
                        
                        if [ -f ~/.config/fish/config.fish ] && grep -q 'starship init fish | source' ~/.config/fish/config.fish 2>/dev/null; then
                            echo "- Fish: CONFIGURADO"
                        else
                            echo "- Fish: NÃO CONFIGURADO"
                        fi
                    else
                        echo "Starship não está instalado."
                    fi
                fi
                ;;
            3)
                if command -v starship &>/dev/null; then
                    echo "Configurando Starship para shells disponíveis..."
                    
                    if [ -f ~/.bashrc ]; then
                        if ! grep -q 'eval "\$(starship init bash)"' ~/.bashrc; then
                            echo 'eval "$(starship init bash)"' >> ~/.bashrc
                            echo "Configurado para Bash."
                        else
                            echo "Bash já estava configurado."
                        fi
                    fi
                    
                    if [ -f ~/.zshrc ]; then
                        if ! grep -q 'eval "\$(starship init zsh)"' ~/.zshrc; then
                            echo 'eval "$(starship init zsh)"' >> ~/.zshrc
                            echo "Configurado para Zsh."
                        else
                            echo "Zsh já estava configurado."
                        fi
                    fi
                    
                    if command -v fish &>/dev/null && [ -f ~/.config/fish/config.fish ]; then
                        if ! grep -q 'starship init fish | source' ~/.config/fish/config.fish; then
                            echo 'starship init fish | source' >> ~/.config/fish/config.fish
                            echo "Configurado para Fish."
                        else
                            echo "Fish já estava configurado."
                        fi
                    fi
                    
                    echo "Configuração concluída. Reinicie os terminais para aplicar."
                else
                    echo "Starship não está instalado."
                fi
                ;;
            4)
                return
                ;;
        esac
    else
        echo "Status: NÃO INSTALADO"
        read -p "Instalar Starship Prompt? (s/n): " -n 1 resposta
        echo
        
        if [ "$resposta" = "s" ]; then
            echo "Instalando Starship Prompt..."
            
            if pacman -Si starship 2>/dev/null | grep -q "Name"; then
                echo "Instalando via pacman..."
                pacman -S --noconfirm starship
            else
                echo "Instalando via script oficial..."
                curl -fsSL https://starship.rs/install.sh | sh -s -- -f -y
            fi
            
            if command -v starship &>/dev/null; then
                echo "Configurando Starship para shells..."
                
                if [ -f ~/.bashrc ]; then
                    if ! grep -q 'eval "\$(starship init bash)"' ~/.bashrc; then
                        echo 'eval "$(starship init bash)"' >> ~/.bashrc
                    fi
                fi
                
                if [ -f ~/.zshrc ]; then
                    if ! grep -q 'eval "\$(starship init zsh)"' ~/.zshrc; then
                        echo 'eval "$(starship init zsh)"' >> ~/.zshrc
                    fi
                fi
                
                if command -v fish &>/dev/null; then
                    mkdir -p ~/.config/fish
                    if [ -f ~/.config/fish/config.fish ]; then
                        if ! grep -q 'starship init fish | source' ~/.config/fish/config.fish; then
                            echo 'starship init fish | source' >> ~/.config/fish/config.fish
                        fi
                    else
                        echo 'starship init fish | source' > ~/.config/fish/config.fish
                    fi
                fi
                
                echo "1" > "$S_STARSHIP"
                echo "Starship Prompt instalado e configurado com sucesso!"
                echo "Reinicie os terminais para começar a usar."
            else
                echo "Erro: Não foi possível instalar o Starship."
            fi
        fi
    fi
    
    read -p "Pressione Enter para continuar..."
}

ohmybash_install() {
    clear
    echo "=== Oh My Bash ==="
    
    _OSH="$HOME/.oh-my-bash"
    
    if [ -f "$S_OHMYBASH" ]; then
        echo "Status: INSTALADO"
        echo "1) Desinstalar"
        echo "2) Ver status"
        echo "3) Reinstalar"
        echo "4) Voltar"
        read -p "> " opt
        
        case $opt in
            1)
                read -p "Deseja remover o Oh My Bash? (s/n): " -n 1 resposta
                echo
                if [ "$resposta" = "s" ]; then
                    if [ -d "$_OSH" ]; then
                        if [ -f "$_OSH/tools/uninstall.sh" ]; then
                            yes | "$_OSH/tools/uninstall.sh"
                        else
                            rm -rf "$_OSH"
                            sed -i '/# OMB/d' ~/.bashrc 2>/dev/null
                            sed -i '/OSH_THEME/d' ~/.bashrc 2>/dev/null
                            sed -i '/completions/d' ~/.bashrc 2>/dev/null
                            sed -i '/aliases/d' ~/.bashrc 2>/dev/null
                        fi
                    fi
                    rm -f "$S_OHMYBASH"
                    echo "Oh My Bash removido. Reinicie o terminal para aplicar."
                fi
                ;;
            2)
                if [ -f "$S_OHMYBASH" ]; then
                    echo "Oh My Bash instalado via este script desde: $(date -r "$S_OHMYBASH")"
                    
                    if [ -d "$_OSH" ]; then
                        echo "Oh My Bash está instalado em: $_OSH"
                        
                        if grep -q 'OSH_THEME' ~/.bashrc 2>/dev/null; then
                            echo "Configurado no .bashrc: SIM"
                            theme=$(grep 'OSH_THEME=' ~/.bashrc | cut -d= -f2 | tr -d '"' | head -1)
                            if [ -n "$theme" ]; then
                                echo "Tema atual: $theme"
                            fi
                        else
                            echo "Configurado no .bashrc: NÃO"
                        fi
                    else
                        echo "Oh My Bash não está instalado."
                    fi
                fi
                ;;
            3)
                read -p "Deseja reinstalar o Oh My Bash? (s/n): " -n 1 resposta
                echo
                if [ "$resposta" = "s" ]; then
                    if [ -d "$_OSH" ]; then
                        rm -rf "$_OSH"
                        sed -i '/# OMB/d' ~/.bashrc 2>/dev/null
                        sed -i '/OSH_THEME/d' ~/.bashrc 2>/dev/null
                        sed -i '/completions/d' ~/.bashrc 2>/dev/null
                        sed -i '/aliases/d' ~/.bashrc 2>/dev/null
                    fi
                    
                    bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" --unattended
                    
                    if [ -d "$_OSH" ]; then
                        echo "1" > "$S_OHMYBASH"
                        echo "Oh My Bash reinstalado com sucesso!"
                        echo "Reinicie o terminal para aplicar."
                    else
                        echo "Erro: Não foi possível reinstalar o Oh My Bash."
                    fi
                fi
                ;;
            4)
                return
                ;;
        esac
    else
        if [ -d "$_OSH" ]; then
            echo "Oh My Bash já está instalado (não via este script)."
            echo "1) Desinstalar"
            echo "2) Registrar no script"
            echo "3) Voltar"
            read -p "> " opt
            
            case $opt in
                1)
                    read -p "Deseja remover o Oh My Bash? (s/n): " -n 1 resposta
                    echo
                    if [ "$resposta" = "s" ]; then
                        if [ -f "$_OSH/tools/uninstall.sh" ]; then
                            yes | "$_OSH/tools/uninstall.sh"
                        else
                            rm -rf "$_OSH"
                            sed -i '/# OMB/d' ~/.bashrc 2>/dev/null
                            sed -i '/OSH_THEME/d' ~/.bashrc 2>/dev/null
                            sed -i '/completions/d' ~/.bashrc 2>/dev/null
                            sed -i '/aliases/d' ~/.bashrc 2>/dev/null
                        fi
                        echo "Oh My Bash removido. Reinicie o terminal para aplicar."
                    fi
                    ;;
                2)
                    echo "1" > "$S_OHMYBASH"
                    echo "Oh My Bash registrado neste script."
                    ;;
                3)
                    return
                    ;;
            esac
        else
            echo "Status: NÃO INSTALADO"
            read -p "Instalar Oh My Bash? (s/n): " -n 1 resposta
            echo
            
            if [ "$resposta" = "s" ]; then
                echo "Instalando Oh My Bash..."
                
                bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" --unattended
                
                if [ -d "$_OSH" ]; then
                    echo "1" > "$S_OHMYBASH"
                    echo "Oh My Bash instalado com sucesso!"
                    echo "Reinicie o terminal para aplicar."
                else
                    echo "Erro: Não foi possível instalar o Oh My Bash."
                fi
            fi
        fi
    fi
    
    read -p "Pressione Enter para continuar..."
}

flathub_install() {
    clear
    echo "=== Flathub ==="
    
    if [ -f "$S_FLATHUB" ]; then
        echo "Status: INSTALADO"
        echo "1) Desinstalar"
        echo "2) Ver status"
        echo "3) Atualizar repositório"
        echo "4) Listar apps instalados"
        echo "5) Voltar"
        read -p "> " opt
        
        case $opt in
            1)
                read -p "Deseja remover o Flathub? (s/n): " -n 1 resposta
                echo
                if [ "$resposta" = "s" ]; then
                    flatpak remote-delete flathub --force 2>/dev/null || true
                    
                    pacman -Rns --noconfirm flatpak 2>/dev/null || true
                    
                    rm -f "$S_FLATHUB"
                    echo "Flathub removido."
                fi
                ;;
            2)
                if [ -f "$S_FLATHUB" ]; then
                    echo "Flathub instalado via este script desde: $(date -r "$S_FLATHUB")"
                    
                    if command -v flatpak &>/dev/null; then
                        echo "Flatpak está instalado."
                        flatpak --version
                        
                        echo ""
                        echo "Remotos configurados:"
                        flatpak remotes
                        
                        echo ""
                        echo "Aplicativos instalados:"
                        flatpak list --app | head -10
                        if flatpak list --app | grep -q .; then
                            echo "(mostrando apenas os primeiros 10)"
                        fi
                    else
                        echo "Flatpak não está instalado."
                    fi
                fi
                ;;
            3)
                if command -v flatpak &>/dev/null; then
                    flatpak update
                    echo "Repositório Flathub atualizado."
                else
                    echo "Flatpak não está instalado."
                fi
                ;;
            4)
                if command -v flatpak &>/dev/null; then
                    echo "Aplicativos Flatpak instalados:"
                    flatpak list --app --columns=application,name,version
                else
                    echo "Flatpak não está instalado."
                fi
                ;;
            5)
                return
                ;;
        esac
    else
        echo "Status: NÃO INSTALADO"
        read -p "Instalar Flathub? (s/n): " -n 1 resposta
        echo
        
        if [ "$resposta" = "s" ]; then
            echo "Instalando Flatpak e configurando Flathub..."
            
            pacman -S --noconfirm flatpak
            
            flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
            
            echo "1" > "$S_FLATHUB"
            echo "Flathub instalado e configurado com sucesso!"
            echo ""
            echo "Reinicie o sistema para que as aplicações Flatpak apareçam nas lojas de aplicativos."
        fi
    fi
    
    read -p "Pressione Enter para continuar..."
}

yay_install() {
    clear
    echo "=== Yay AUR Helper ==="
    
    if [ -f "$S_YAY" ]; then
        echo "Status: INSTALADO"
        echo "1) Desinstalar"
        echo "2) Ver status"
        echo "3) Atualizar Yay"
        echo "4) Voltar"
        read -p "> " opt
        
        case $opt in
            1)
                read -p "Deseja remover o Yay? (s/n): " -n 1 resposta
                echo
                if [ "$resposta" = "s" ]; then
                    pacman -Rns --noconfirm yay 2>/dev/null || true
                    
                    if [ -f /usr/bin/yay ]; then
                        rm -f /usr/bin/yay 2>/dev/null || true
                    fi
                    
                    rm -f "$S_YAY"
                    echo "Yay removido."
                fi
                ;;
            2)
                if [ -f "$S_YAY" ]; then
                    echo "Yay instalado via este script desde: $(date -r "$S_YAY")"
                    
                    if command -v yay &>/dev/null; then
                        echo "Yay está instalado."
                        yay --version
                        
                        echo ""
                        echo "Verificando se Chaotic AUR está configurado..."
                        if grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
                            echo "Chaotic AUR: CONFIGURADO"
                        else
                            echo "Chaotic AUR: NÃO CONFIGURADO"
                            echo "Nota: Yay foi instalado via pacman com base-devel"
                        fi
                    else
                        echo "Yay não está instalado."
                    fi
                fi
                ;;
            3)
                if command -v yay &>/dev/null; then
                    yay -Syu
                    echo "Yay e pacotes atualizados."
                else
                    echo "Yay não está instalado."
                fi
                ;;
            4)
                return
                ;;
        esac
    else
        echo "Status: NÃO INSTALADO"
        echo "AVISO: É recomendado instalar o Chaotic AUR primeiro para facilitar a instalação."
        read -p "Instalar Yay AUR Helper? (s/n): " -n 1 resposta
        echo
        
        if [ "$resposta" = "s" ]; then
            echo "Instalando Yay AUR Helper..."
            
            if grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
                echo "Usando Chaotic AUR para instalar yay..."
                pacman -S --noconfirm yay
            else
                echo "Chaotic AUR não encontrado. Instalando via método tradicional..."
                
                pacman -S --noconfirm base-devel git
                
                if [ -d /tmp/yay ]; then
                    rm -rf /tmp/yay
                fi
                
                git clone https://aur.archlinux.org/yay.git /tmp/yay
                cd /tmp/yay
                makepkg -si --noconfirm
                cd ~
            fi
            
            if command -v yay &>/dev/null; then
                echo "1" > "$S_YAY"
                echo "Yay AUR Helper instalado com sucesso!"
                echo ""
                echo "Comandos úteis:"
                echo "- yay -Syu          # Atualizar sistema e AUR"
                echo "- yay -S pacote     # Instalar do AUR"
                echo "- yay -Rns pacote   # Remover pacote"
            else
                echo "Erro: Não foi possível instalar o Yay."
            fi
        fi
    fi
    
    read -p "Pressione Enter para continuar..."
}

lazyman_install() {
    clear
    echo "=== Lazyman / LazyVim ==="
    
    if [ -f "$S_LAZYMAN" ]; then
        echo "Status: INSTALADO"
        echo "1) Desinstalar"
        echo "2) Ver status"
        echo "3) Instalar LazyVim direto"
        echo "4) Reinstalar Lazyman"
        echo "5) Voltar"
        read -p "> " opt
        
        case $opt in
            1)
                read -p "Deseja remover? (1=Lazyman, 2=LazyVim): " remover_opcao
                echo
                if [ "$remover_opcao" = "1" ]; then
                    if [ -d "$HOME/.config/nvim-Lazyman" ]; then
                        rm -rf "$HOME/.config/nvim-Lazyman"
                        echo "Lazyman removido."
                    fi
                elif [ "$remover_opcao" = "2" ]; then
                    if [ -d "$HOME/.config/nvim" ]; then
                        rm -rf "$HOME/.config/nvim"
                        echo "LazyVim removido."
                    fi
                fi
                
                if [ ! -d "$HOME/.config/nvim-Lazyman" ] && [ ! -d "$HOME/.config/nvim" ]; then
                    pacman -Rns --noconfirm neovim 2>/dev/null || true
                    rm -f "$S_LAZYMAN"
                    echo "Neovim removido."
                else
                    echo "Mantendo Neovim (outras configurações ainda existem)."
                fi
                ;;
            2)
                if [ -f "$S_LAZYMAN" ]; then
                    echo "Instalado via este script desde: $(date -r "$S_LAZYMAN")"
                    
                    if [ -d "$HOME/.config/nvim-Lazyman" ]; then
                        echo "Lazyman: INSTALADO em ~/.config/nvim-Lazyman"
                    fi
                    
                    if [ -d "$HOME/.config/nvim" ]; then
                        echo "LazyVim: INSTALADO em ~/.config/nvim"
                    fi
                    
                    if command -v nvim &>/dev/null; then
                        echo "Neovim: INSTALADO"
                        nvim --version | head -1
                    else
                        echo "Neovim: NÃO INSTALADO"
                    fi
                fi
                ;;
            3)
                read -p "Instalar LazyVim direto (isso substituirá configurações existentes)? (s/n): " -n 1 resposta
                echo
                if [ "$resposta" = "s" ]; then
                    echo "Instalando LazyVim direto..."
                    
                    pacman -S --noconfirm neovim git
                    
                    if [ -d "$HOME/.config/nvim" ]; then
                        rm -rf "$HOME/.config/nvim"
                    fi
                    
                    git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
                    
                    rm -rf "$HOME/.config/nvim/.git"
                    
                    echo "1" > "$S_LAZYMAN"
                    echo "LazyVim instalado diretamente com sucesso!"
                    echo ""
                    echo "Localização: ~/.config/nvim"
                    echo "Execute 'nvim' para iniciar o LazyVim."
                fi
                ;;
            4)
                read -p "Reinstalar Lazyman? (s/n): " -n 1 resposta
                echo
                if [ "$resposta" = "s" ]; then
                    echo "Reinstalando Lazyman..."
                    
                    if [ -d "$HOME/.config/nvim-Lazyman" ]; then
                        rm -rf "$HOME/.config/nvim-Lazyman"
                    fi
                    
                    pacman -S --noconfirm neovim git
                    
                    git clone --depth=1 https://github.com/doctorfree/nvim-lazyman "$HOME/.config/nvim-Lazyman"
                    
                    if [ -f "$HOME/.config/nvim-Lazyman/lazyman.sh" ]; then
                        echo "Lazyman reinstalado com sucesso!"
                        echo ""
                        echo "Execute a instalação do Lazyman para escolher uma configuração de Neovim."
                    else
                        echo "Erro: Não foi possível reinstalar o Lazyman."
                    fi
                fi
                ;;
            5)
                return
                ;;
        esac
    else
        echo "Status: NÃO INSTALADO"
        echo "1) Instalar Lazyman (gerenciador de configurações Neovim)"
        echo "2) Instalar LazyVim diretamente"
        echo "3) Voltar"
        read -p "> " opt
        
        case $opt in
            1)
                read -p "Instalar Lazyman? (s/n): " -n 1 resposta
                echo
                if [ "$resposta" = "s" ]; then
                    echo "Instalando Lazyman..."
                    
                    if [ -f "$HOME/.config/nvim-Lazyman/lazyman.sh" ]; then
                        echo "Lazyman já está instalado."
                        echo "1" > "$S_LAZYMAN"
                        return
                    fi
                    
                    pacman -S --noconfirm neovim git
                    
                    git clone --depth=1 https://github.com/doctorfree/nvim-lazyman "$HOME/.config/nvim-Lazyman"
                    
                    if [ -f "$HOME/.config/nvim-Lazyman/lazyman.sh" ]; then
                        echo "Lazyman instalado com sucesso!"
                        echo ""
                        echo "O Lazyman está instalado em ~/.config/nvim-Lazyman"
                        echo "Execute ~/.config/nvim-Lazyman/lazyman.sh para escolher uma configuração."
                        
                        echo "1" > "$S_LAZYMAN"
                    else
                        echo "Erro: Não foi possível instalar o Lazyman."
                    fi
                fi
                ;;
            2)
                read -p "Instalar LazyVim direto? (s/n): " -n 1 resposta
                echo
                if [ "$resposta" = "s" ]; then
                    echo "Instalando LazyVim diretamente..."
                    
                    pacman -S --noconfirm neovim git
                    
                    if [ -d "$HOME/.config/nvim" ]; then
                        read -p "Configuração Neovim existente será substituída. Continuar? (s/n): " -n 1 confirmacao
                        echo
                        if [ "$confirmacao" != "s" ]; then
                            return
                        fi
                        rm -rf "$HOME/.config/nvim"
                    fi
                    
                    git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
                    
                    rm -rf "$HOME/.config/nvim/.git"
                    
                    echo "1" > "$S_LAZYMAN"
                    echo "LazyVim instalado diretamente com sucesso!"
                    echo ""
                    echo "Localização: ~/.config/nvim"
                    echo "Execute 'nvim' para iniciar o LazyVim."
                fi
                ;;
            3)
                return
                ;;
        esac
    fi
    
    read -p "Pressione Enter para continuar..."
}

cpu_ondemand() {
    clear
    echo "=== CPU Ondemand Governor ==="
    
    if [ -f "$S_ONDEMAND" ]; then
        echo "Status: INSTALADO"
        echo "1) Desinstalar"
        echo "2) Ver status"
        echo "3) Reiniciar serviço"
        echo "4) Voltar"
        read -p "> " opt
        
        case $opt in
            1)
                read -p "Deseja remover o Ondemand Governor? (s/n): " -n 1 resposta
                echo
                if [ "$resposta" = "s" ]; then
                    if [ -f /etc/systemd/system/set-ondemand-governor.service ]; then
                        systemctl disable set-ondemand-governor.service --now 2>/dev/null
                        rm -f /etc/systemd/system/set-ondemand-governor.service
                    fi
                    
                    if [ -f /etc/default/grub.d/01_intel_pstate_disable ]; then
                        rm -f /etc/default/grub.d/01_intel_pstate_disable
                        grub-mkconfig -o /boot/grub/grub.cfg
                    fi
                    
                    if [ -d /etc/kernel/cmdline.d ]; then
                        rm -f /etc/kernel/cmdline.d/10-intel-pstate-disable.conf 2>/dev/null
                        bootctl update 2>/dev/null || true
                    fi
                    
                    rm -f "$S_ONDEMAND"
                    echo "Ondemand Governor removido. Reinicie para aplicar."
                fi
                ;;
            2)
                if [ -f "$S_ONDEMAND" ]; then
                    echo "Ondemand Governor instalado via este script desde: $(date -r "$S_ONDEMAND")"
                    
                    if [ -f /etc/systemd/system/set-ondemand-governor.service ]; then
                        echo "Serviço systemd: INSTALADO"
                        if systemctl is-active set-ondemand-governor.service &>/dev/null; then
                            echo "Status do serviço: ATIVO"
                        else
                            echo "Status do serviço: INATIVO"
                        fi
                    else
                        echo "Serviço systemd: NÃO INSTALADO"
                    fi
                    
                    if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]; then
                        echo "Governor atual (CPU0): $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)"
                    fi
                fi
                ;;
            3)
                if [ -f /etc/systemd/system/set-ondemand-governor.service ]; then
                    systemctl restart set-ondemand-governor.service
                    echo "Serviço Ondemand Governor reiniciado."
                else
                    echo "Serviço não está instalado."
                fi
                ;;
            4)
                return
                ;;
        esac
    else
        echo "Status: NÃO INSTALADO"
        read -p "Instalar CPU Ondemand Governor? (s/n): " -n 1 resposta
        echo
        
        if [ "$resposta" = "s" ]; then
            echo "Instalando CPU Ondemand Governor..."
            
            if [ -f /etc/systemd/system/set-ondemand-governor.service ]; then
                echo "Ondemand Governor já está instalado."
                echo "1" > "$S_ONDEMAND"
                read -p "Pressione Enter para continuar..."
                return
            fi
            
            mkdir -p /etc/systemd/system
            cat > /etc/systemd/system/set-ondemand-governor.service << 'EOF'
[Unit]
Description=Set CPU governor to ondemand
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c "echo ondemand | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor"
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
            
            if ! grep -q "intel_pstate=disable" /proc/cmdline; then
                if [ -f /boot/grub/grub.cfg ] || [ -f /etc/default/grub ]; then
                    mkdir -p /etc/default/grub.d
                    echo 'GRUB_CMDLINE_LINUX_DEFAULT="$GRUB_CMDLINE_LINUX_DEFAULT intel_pstate=disable"' > /etc/default/grub.d/01_intel_pstate_disable
                    grub-mkconfig -o /boot/grub/grub.cfg
                fi
            fi
            
            systemctl enable set-ondemand-governor.service
            systemctl start set-ondemand-governor.service
            
            echo "1" > "$S_ONDEMAND"
            echo "CPU Ondemand Governor instalado com sucesso!"
            echo "Reinicie para que as alterações do kernel sejam aplicadas."
            read -p "Pressione Enter para continuar..."
            return
        else
            read -p "Pressione Enter para continuar..."
            return
        fi
    fi
    
    read -p "Pressione Enter para continuar..."
}

ananicy_install() {
    clear
    echo "=== Ananicy-cpp (Auto Nice daemon) ==="
    
    if [ -f "$S_ANANICY" ]; then
        echo "Status: INSTALADO"
        echo "1) Desinstalar"
        echo "2) Ver status"
        echo "3) Reiniciar serviço"
        echo "4) Voltar"
        read -p "> " opt
        
        case $opt in
            1)
                read -p "Deseja remover o Ananicy-cpp? (s/n): " -n 1 resposta
                echo
                if [ "$resposta" = "s" ]; then
                    systemctl disable ananicy-cpp.service --now 2>/dev/null
                    pacman -Rns --noconfirm ananicy-cpp cachyos-ananicy-rules-git 2>/dev/null || true
                    rm -f "$S_ANANICY"
                    echo "Ananicy-cpp removido."
                fi
                ;;
            2)
                if [ -f "$S_ANANICY" ]; then
                    echo "Ananicy-cpp instalado via este script desde: $(date -r "$S_ANANICY")"
                    
                    if systemctl is-active ananicy-cpp.service &>/dev/null; then
                        echo "Serviço: ATIVO"
                        echo ""
                        echo "Regras instaladas:"
                        ls /etc/ananicy.d/ 2>/dev/null | head -10
                    else
                        echo "Serviço: INATIVO"
                    fi
                fi
                ;;
            3)
                systemctl restart ananicy-cpp.service
                echo "Serviço Ananicy-cpp reiniciado."
                ;;
            4)
                return
                ;;
        esac
    else
        echo "Status: NÃO INSTALADO"
        echo "Ananicy-cpp é um daemon para ajustar automaticamente a nice value (prioridade)"
        echo "de processos com base em regras predefinidas."
        read -p "Instalar Ananicy-cpp? (s/n): " -n 1 resposta
        echo
        
        if [ "$resposta" = "s" ]; then
            echo "Instalando Ananicy-cpp..."
            
            if ! grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
                echo "AVISO: Chaotic AUR não está instalado. Instalando primeiro..."
                chaotic_aur
                if ! grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
                    echo "Erro: Chaotic AUR necessário para instalar Ananicy-cpp."
                    read -p "Pressione Enter para continuar..."
                    return
                fi
            fi
            
            pacman -Syu --noconfirm
            pacman -S --noconfirm ananicy-cpp cachyos-ananicy-rules-git
            
            systemctl enable ananicy-cpp.service
            systemctl start ananicy-cpp.service
            
            echo "1" > "$S_ANANICY"
            echo "Ananicy-cpp instalado com sucesso!"
            echo "O serviço foi configurado para iniciar automaticamente."
            echo "Reinicie para aplicações completas."
        fi
    fi
    
    read -p "Pressione Enter para continuar..."
}

archsb_install() {
    clear
    echo "=== Arch Secure Boot (sbctl) ==="
    
    if [ -f "$S_ARCHSB" ]; then
        echo "Status: INSTALADO"
        echo "1) Verificar status"
        echo "2) Criar/renovar chaves"
        echo "3) Verificar arquivos assinados"
        echo "4) Desinstalar"
        echo "5) Voltar"
        read -p "> " opt
        
        case $opt in
            1)
                echo "Status do Secure Boot:"
                sbctl status
                echo ""
                echo "Arquivos verificados:"
                sbctl verify
                ;;
            2)
                read -p "Criar e inscrever novas chaves? (s/n): " -n 1 resposta
                echo
                if [ "$resposta" = "s" ]; then
                    sudo sbctl remove-keys 2>/dev/null || true
                    sudo sbctl create-keys
                    sudo sbctl enroll-keys -m -f
                    
                    if command -v grub-install &>/dev/null; then
                        echo "Assinando GRUB..."
                        sudo grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --modules="tpm" --disable-shim-lock
                    fi
                    
                    while IFS= read -r line; do
                        if [[ "$line" =~ ✗ ]]; then
                            file=$(echo "$line" | awk '{print $2}')
                            echo "Assinando: $file"
                            sudo sbctl sign -s "$file"
                        fi
                    done < <(sudo sbctl verify)
                    
                    echo "Todas as chaves foram criadas e arquivos assinados."
                    sudo sbctl verify
                fi
                ;;
            3)
                echo "Verificando arquivos assinados:"
                sbctl verify
                ;;
            4)
                read -p "Deseja remover o sbctl? (s/n): " -n 1 resposta
                echo
                if [ "$resposta" = "s" ]; then
                    pacman -Rns --noconfirm sbctl efibootmgr 2>/dev/null || true
                    rm -f "$S_ARCHSB"
                    echo "sbctl removido."
                fi
                ;;
            5)
                return
                ;;
        esac
    else
        echo "Status: NÃO INSTALADO"
        echo "sbctl é uma ferramenta para gerenciar Secure Boot no Arch Linux."
        echo ""
        echo "AVISO: Esta operação envolve a configuração de Secure Boot."
        echo "Certifique-se de estar em modo Setup Mode no firmware UEFI."
        read -p "Instalar e configurar Secure Boot? (s/n): " -n 1 resposta
        echo
        
        if [ "$resposta" = "s" ]; then
            echo "Instalando sbctl e efibootmgr..."
            
            pacman -S --noconfirm sbctl efibootmgr
            
            sleep 1
            
            echo "Verificando status do Secure Boot..."
            
            if sbctl status | grep -i 'secure boot' | grep -qi 'disabled'; then
                if sbctl status | grep -i 'setup mode' | grep -qi 'enabled'; then
                    echo "Secure Boot desativado e Setup Mode ativado - OK"
                    
                    if command -v grub-install &>/dev/null; then
                        echo "Configurando GRUB para Secure Boot..."
                        sudo grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --modules="tpm" --disable-shim-lock
                    fi
                    
                    echo "Criando chaves Secure Boot..."
                    sudo sbctl create-keys
                    sudo sbctl enroll-keys -m -f
                    
                    echo "Assinando arquivos do sistema..."
                    while IFS= read -r line; do
                        if [[ "$line" =~ ✗ ]]; then
                            file=$(echo "$line" | awk '{print $2}')
                            echo "Assinando: $file"
                            sudo sbctl sign -s "$file"
                        fi
                    done < <(sudo sbctl verify)
                    
                    echo "Verificando assinaturas..."
                    sudo sbctl verify
                    
                    echo "1" > "$S_ARCHSB"
                    echo ""
                    echo "Secure Boot configurado com sucesso!"
                    echo "Reinicie o sistema e ative o Secure Boot no firmware UEFI."
                else
                    echo "ERRO: Setup Mode não está ativado."
                    echo "Entre no firmware UEFI e ative o Setup Mode."
                    read -p "Pressione Enter para continuar..."
                    return
                fi
            else
                echo "Secure Boot já está ativado no sistema."
                echo "1" > "$S_ARCHSB"
                echo "sbctl instalado para gerenciamento."
            fi
        fi
    fi
    
    read -p "Pressione Enter para continuar..."
}

btrfs_assistant_install() {
    clear
    echo "=== Btrfs Assistant ==="
    
    if ! findmnt -n -o FSTYPE / | grep -q "btrfs"; then
        echo "ERRO: Sistema de arquivos raiz não é Btrfs."
        echo "Esta ferramenta só funciona com Btrfs."
        read -p "Pressione Enter para continuar..."
        return
    fi
    
    if [ -f "$S_BTRFS" ]; then
        echo "Status: INSTALADO"
        echo "1) Desinstalar"
        echo "2) Ver status"
        echo "3) Iniciar Btrfs Assistant"
        echo "4) Configurar Snapper"
        echo "5) Voltar"
        read -p "> " opt
        
        case $opt in
            1)
                read -p "Deseja remover o Btrfs Assistant? (s/n): " -n 1 resposta
                echo
                if [ "$resposta" = "s" ]; then
                    pacman -Rns --noconfirm btrfs-assistant snapper 2>/dev/null || true
                    rm -f "$S_BTRFS"
                    echo "Btrfs Assistant removido."
                fi
                ;;
            2)
                if [ -f "$S_BTRFS" ]; then
                    echo "Btrfs Assistant instalado via este script desde: $(date -r "$S_BTRFS")"
                    
                    if command -v btrfs-assistant &>/dev/null; then
                        echo "Btrfs Assistant: INSTALADO"
                    else
                        echo "Btrfs Assistant: NÃO INSTALADO"
                    fi
                    
                    if command -v snapper &>/dev/null; then
                        echo "Snapper: INSTALADO"
                        echo ""
                        echo "Configurações Snapper:"
                        snapper list-configs 2>/dev/null || echo "Nenhuma configuração encontrada"
                    fi
                fi
                ;;
            3)
                if command -v btrfs-assistant &>/dev/null; then
                    echo "Iniciando Btrfs Assistant..."
                    btrfs-assistant &
                    echo "Aplicação iniciada em segundo plano."
                else
                    echo "Btrfs Assistant não está instalado."
                fi
                ;;
            4)
                if command -v snapper &>/dev/null; then
                    echo "Configuração básica do Snapper:"
                    echo ""
                    echo "1) Criar configuração padrão"
                    echo "2) Listar configurações existentes"
                    echo "3) Criar snapshot manual"
                    echo "4) Listar snapshots"
                    read -p "> " snapper_opt
                    
                    case $snapper_opt in
                        1)
                            echo "Criando configuração padrão para raiz (/)..."
                            snapper -c root create-config /
                            echo "Configuração criada."
                            ;;
                        2)
                            echo "Configurações do Snapper:"
                            snapper list-configs
                            ;;
                        3)
                            read -p "Descrição do snapshot: " description
                            if [ -n "$description" ]; then
                                snapper -c root create --description "$description"
                                echo "Snapshot criado."
                            else
                                echo "Descrição não fornecida."
                            fi
                            ;;
                        4)
                            echo "Snapshots existentes:"
                            snapper -c root list
                            ;;
                    esac
                else
                    echo "Snapper não está instalado."
                fi
                ;;
            5)
                return
                ;;
        esac
    else
        echo "Status: NÃO INSTALADO"
        echo "Btrfs Assistant é uma interface gráfica para gerenciar sistemas de arquivos Btrfs."
        echo "Inclui também o Snapper para gerenciamento de snapshots."
        read -p "Instalar Btrfs Assistant? (s/n): " -n 1 resposta
        echo
        
        if [ "$resposta" = "s" ]; then
            echo "Instalando Btrfs Assistant e Snapper..."
            
            pacman -S --noconfirm btrfs-assistant snapper
            
            if ! snapper list-configs 2>/dev/null | grep -q "root"; then
                snapper -c root create-config /
                echo "Configuração padrão do Snapper criada para /"
            fi
            
            echo "1" > "$S_BTRFS"
            echo "Btrfs Assistant instalado com sucesso!"
            echo ""
            echo "Para usar o Btrfs Assistant, execute: btrfs-assistant"
            echo "Para snapshots automáticos, configure o serviço do Snapper."
        fi
    fi
    
    read -p "Pressione Enter para continuar..."
}

cachyconfs_install() {
    clear
    echo "=== CachyOS Configurações de Otimização ==="
    
    if [ -f "$S_CACHYCONFS" ]; then
        echo "Status: INSTALADO"
        echo "1) Verificar configurações"
        echo "2) Atualizar configurações"
        echo "3) Remover configurações"
        echo "4) Voltar"
        read -p "> " opt
        
        case $opt in
            1)
                echo "Configurações CachyOS ativas:"
                echo ""
                
                if [ -f /usr/lib/sysctl.d/99-cachyos-settings.conf ]; then
                    echo "Sysctl configs: INSTALADO"
                    echo "Conteúdo:"
                    cat /usr/lib/sysctl.d/99-cachyos-settings.conf | head -20
                    if [ $(cat /usr/lib/sysctl.d/99-cachyos-settings.conf | wc -l) -gt 20 ]; then
                        echo "... (mostrando primeiras 20 linhas)"
                    fi
                else
                    echo "Sysctl configs: NÃO INSTALADO"
                fi
                
                echo ""
                echo "Otimizações do kernel (se aplicável):"
                cat /proc/cmdline | grep -o "mitigations=[^ ]*" 2>/dev/null || echo "Nenhuma configuração de mitigação encontrada"
                ;;
            2)
                read -p "Atualizar configurações CachyOS? (s/n): " -n 1 resposta
                echo
                if [ "$resposta" = "s" ]; then
                    echo "Atualizando configurações CachyOS..."
                    
                    rm -f /usr/lib/sysctl.d/99-cachyos-settings.conf 2>/dev/null
                    
                    mkdir -p /usr/lib/sysctl.d/
                    
                    cat > /usr/lib/sysctl.d/99-cachyos-settings.conf << 'EOF'
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_notsent_lowat = 16384
net.core.default_qdisc = fq
net.ipv4.tcp_fastopen = 3
vm.swappiness = 10
vm.vfs_cache_pressure = 50
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5
vm.dirty_expire_centisecs = 3000
vm.dirty_writeback_centisecs = 500
fs.file-max = 2097152
fs.inotify.max_user_watches = 524288
kernel.sched_migration_cost_ns = 5000000
kernel.sched_autogroup_enabled = 1
kernel.perf_cpu_time_max_percent = 20
EOF
                    
                    sysctl --system
                    
                    echo "Configurações atualizadas. Reinicie para aplicar."
                fi
                ;;
            3)
                read -p "Remover configurações CachyOS? (s/n): " -n 1 resposta
                echo
                if [ "$resposta" = "s" ]; then
                    echo "Removendo configurações CachyOS..."
                    
                    rm -f /usr/lib/sysctl.d/99-cachyos-settings.conf 2>/dev/null
                    rm -f "$S_CACHYCONFS"
                    
                    echo "Configurações removidas. Reinicie para aplicar."
                fi
                ;;
            4)
                return
                ;;
        esac
    else
        echo "Status: NÃO INSTALADO"
        echo "Configurações de otimização do CachyOS para melhor desempenho."
        echo "Inclui ajustes de sysctl para melhorar a responsividade do sistema."
        read -p "Instalar configurações CachyOS? (s/n): " -n 1 resposta
        echo
        
        if [ "$resposta" = "s" ]; then
            echo "Instalando configurações CachyOS..."
            
            mkdir -p /usr/lib/sysctl.d/
            
            cat > /usr/lib/sysctl.d/99-cachyos-settings.conf << 'EOF'
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_notsent_lowat = 16384
net.core.default_qdisc = fq
net.ipv4.tcp_fastopen = 3
vm.swappiness = 10
vm.vfs_cache_pressure = 50
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5
vm.dirty_expire_centisecs = 3000
vm.dirty_writeback_centisecs = 500
fs.file-max = 2097152
fs.inotify.max_user_watches = 524288
kernel.sched_migration_cost_ns = 5000000
kernel.sched_autogroup_enabled = 1
kernel.perf_cpu_time_max_percent = 20
EOF
            
            sysctl --system
            
            echo "1" > "$S_CACHYCONFS"
            echo "Configurações CachyOS instaladas com sucesso!"
            echo "Reinicie para aplicações completas."
        fi
    fi
    
    read -p "Pressione Enter para continuar..."
}

hwaccel_flatpak_install() {
    clear
    echo "=== HW Acceleration para Flatpak ==="
    
    if [ -f "$S_HWACCEL_FLATPAK" ]; then
        echo "Status: INSTALADO"
        echo "1) Verificar status"
        echo "2) Atualizar configuração"
        echo "3) Desinstalar"
        echo "4) Voltar"
        read -p "> " opt
        
        case $opt in
            1)
                echo "Status da aceleração por hardware para Flatpak:"
                echo ""
                
                if command -v flatpak &>/dev/null; then
                    echo "Flatpak instalado: SIM"
                    echo ""
                    echo "Configurações ativas:"
                    
                    if [ -f /etc/environment ]; then
                        echo "Variáveis de ambiente:"
                        grep -i "flatpak\|wayland\|nvidia\|vaapi" /etc/environment || echo "Nenhuma variável específica encontrada"
                    fi
                    
                    echo ""
                    echo "Overrides do Flatpak:"
                    flatpak override --show 2>/dev/null | head -20 || echo "Nenhum override configurado"
                else
                    echo "Flatpak não está instalado."
                fi
                ;;
            2)
                echo "Atualizando configuração de HW Acceleration..."
                
                mkdir -p /etc/profile.d/
                
                cat > /etc/profile.d/flatpak-hwaccel.sh << 'EOF'
export FLATPAK_GL_DRIVERS="nvidia"
export GALLIUM_DRIVER="zink"
export __GLX_VENDOR_LIBRARY_NAME="nvidia"
export VK_ICD_FILENAMES="/usr/share/vulkan/icd.d/nvidia_icd.json"
export LIBVA_DRIVER_NAME="nvidia"
export NVD_BACKEND="direct"
export MOZ_ENABLE_WAYLAND=1
export QT_QPA_PLATFORM=wayland
export GDK_BACKEND=wayland,x11
export CLUTTER_BACKEND=wayland
export SDL_VIDEODRIVER=wayland
export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=sway
export WLR_NO_HARDWARE_CURSORS=1
export WLR_RENDERER=vulkan
export _JAVA_AWT_WM_NONREPARENTING=1
export NO_AT_BRIDGE=1
EOF
                
                if [ -f /etc/environment ]; then
                    echo "Atualizando /etc/environment..."
                    sed -i '/FLATPAK_GL_DRIVERS\|GALLIUM_DRIVER\|__GLX_VENDOR_LIBRARY_NAME\|VK_ICD_FILENAMES\|LIBVA_DRIVER_NAME\|NVD_BACKEND/d' /etc/environment
                    
                    cat >> /etc/environment << 'EOF'
FLATPAK_GL_DRIVERS="nvidia"
GALLIUM_DRIVER="zink"
__GLX_VENDOR_LIBRARY_NAME="nvidia"
VK_ICD_FILENAMES="/usr/share/vulkan/icd.d/nvidia_icd.json"
LIBVA_DRIVER_NAME="nvidia"
NVD_BACKEND="direct"
MOZ_ENABLE_WAYLAND=1
QT_QPA_PLATFORM=wayland
GDK_BACKEND=wayland,x11
CLUTTER_BACKEND=wayland
SDL_VIDEODRIVER=wayland
XDG_SESSION_TYPE=wayland
EOF
                fi
                
                echo "Configuração atualizada. Reinicie para aplicar."
                ;;
            3)
                read -p "Deseja remover a configuração de HW Acceleration? (s/n): " -n 1 resposta
                echo
                if [ "$resposta" = "s" ]; then
                    rm -f /etc/profile.d/flatpak-hwaccel.sh 2>/dev/null
                    
                    if [ -f /etc/environment ]; then
                        sed -i '/FLATPAK_GL_DRIVERS\|GALLIUM_DRIVER\|__GLX_VENDOR_LIBRARY_NAME\|VK_ICD_FILENAMES\|LIBVA_DRIVER_NAME\|NVD_BACKEND/d' /etc/environment
                    fi
                    
                    rm -f "$S_HWACCEL_FLATPAK"
                    echo "Configuração de HW Acceleration removida."
                fi
                ;;
            4)
                return
                ;;
        esac
    else
        echo "Status: NÃO INSTALADO"
        echo "Configuração de aceleração por hardware para aplicativos Flatpak."
        echo "Melhora o desempenho de aplicativos Flatpak com GPU NVIDIA/AMD/Intel."
        read -p "Configurar HW Acceleration para Flatpak? (s/n): " -n 1 resposta
        echo
        
        if [ "$resposta" = "s" ]; then
            echo "Configurando HW Acceleration para Flatpak..."
            
            if ! command -v flatpak &>/dev/null; then
                echo "Flatpak não está instalado. Instalando..."
                pacman -S --noconfirm flatpak
            fi
            
            mkdir -p /etc/profile.d/
            
            cat > /etc/profile.d/flatpak-hwaccel.sh << 'EOF'
export FLATPAK_GL_DRIVERS="nvidia"
export GALLIUM_DRIVER="zink"
export __GLX_VENDOR_LIBRARY_NAME="nvidia"
export VK_ICD_FILENAMES="/usr/share/vulkan/icd.d/nvidia_icd.json"
export LIBVA_DRIVER_NAME="nvidia"
export NVD_BACKEND="direct"
export MOZ_ENABLE_WAYLAND=1
export QT_QPA_PLATFORM=wayland
export GDK_BACKEND=wayland,x11
export CLUTTER_BACKEND=wayland
export SDL_VIDEODRIVER=wayland
export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=sway
export WLR_NO_HARDWARE_CURSORS=1
export WLR_RENDERER=vulkan
export _JAVA_AWT_WM_NONREPARENTING=1
export NO_AT_BRIDGE=1
EOF
            
            if [ -f /etc/environment ]; then
                cat >> /etc/environment << 'EOF'
FLATPAK_GL_DRIVERS="nvidia"
GALLIUM_DRIVER="zink"
__GLX_VENDOR_LIBRARY_NAME="nvidia"
VK_ICD_FILENAMES="/usr/share/vulkan/icd.d/nvidia_icd.json"
LIBVA_DRIVER_NAME="nvidia"
NVD_BACKEND="direct"
MOZ_ENABLE_WAYLAND=1
QT_QPA_PLATFORM=wayland
GDK_BACKEND=wayland,x11
CLUTTER_BACKEND=wayland
SDL_VIDEODRIVER=wayland
XDG_SESSION_TYPE=wayland
EOF
            fi
            
            echo "Configurando overrides do Flatpak..."
            
            if lspci | grep -qi 'nvidia'; then
                flatpak override --user --env=FLATPAK_GL_DRIVERS=nvidia 2>/dev/null || true
                flatpak override --user --env=__GLX_VENDOR_LIBRARY_NAME=nvidia 2>/dev/null || true
                flatpak override --user --env=VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json 2>/dev/null || true
            fi
            
            flatpak override --user --env=MOZ_ENABLE_WAYLAND=1 2>/dev/null || true
            flatpak override --user --env=QT_QPA_PLATFORM=wayland 2>/dev/null || true
            flatpak override --user --env=GDK_BACKEND=wayland,x11 2>/dev/null || true
            
            echo "1" > "$S_HWACCEL_FLATPAK"
            echo "HW Acceleration para Flatpak configurado com sucesso!"
            echo "Reinicie para aplicar as configurações."
        fi
    fi
    
    read -p "Pressione Enter para continuar..."
}

swapfile_install() {
    clear
    echo "=== Gerenciador de Swapfile ==="
    
    if [ -f "$S_SWAPFILE" ]; then
        echo "Status: INSTALADO"
        echo "1) Verificar swap"
        echo "2) Criar novo swapfile"
        echo "3) Remover swapfile"
        echo "4) Desinstalar gerenciador"
        echo "5) Voltar"
        read -p "> " opt
        
        case $opt in
            1)
                echo "Status do swap:"
                echo ""
                swapon --show
                echo ""
                echo "Uso de memória:"
                free -h
                ;;
            2)
                echo "Criar novo swapfile:"
                echo ""
                echo "1) Criar no diretório raiz (/)"
                echo "2) Criar no diretório home (/home)"
                echo "3) Voltar"
                read -p "> " swap_opt
                
                case $swap_opt in
                    1)
                        echo "Criando swapfile no diretório raiz..."
                        
                        if findmnt -n -o FSTYPE / | grep -q "btrfs"; then
                            echo "Sistema de arquivos Btrfs detectado..."
                            if [ ! -d /swap ]; then
                                btrfs subvolume create /swap
                            fi
                            btrfs filesystem mkswapfile --size 8g --uuid clear /swap/swapfile
                            swapon /swap/swapfile
                            echo "/swap/swapfile none swap defaults 0 0" | tee -a /etc/fstab
                            echo "Swapfile Btrfs criado com sucesso em /swap/swapfile"
                        else
                            echo "Criando swapfile tradicional..."
                            dd if=/dev/zero of=/swapfile bs=1G count=8 status=progress
                            chmod 600 /swapfile
                            mkswap /swapfile
                            swapon /swapfile
                            echo "/swapfile none swap defaults 0 0" | tee -a /etc/fstab
                            echo "Swapfile criado com sucesso em /swapfile"
                        fi
                        echo "1" > "$S_SWAPFILE"
                        ;;
                    2)
                        echo "Criando swapfile no diretório home..."
                        
                        if findmnt -n -o FSTYPE /home | grep -q "btrfs"; then
                            echo "Sistema de arquivos Btrfs detectado..."
                            if [ ! -d /home/swap ]; then
                                btrfs subvolume create /home/swap
                            fi
                            btrfs filesystem mkswapfile --size 8g --uuid clear /home/swap/swapfile
                            swapon /home/swap/swapfile
                            echo "/home/swap/swapfile none swap defaults 0 0" | tee -a /etc/fstab
                            echo "Swapfile Btrfs criado com sucesso em /home/swap/swapfile"
                        else
                            echo "Criando swapfile tradicional..."
                            dd if=/dev/zero of=/home/swapfile bs=1G count=8 status=progress
                            chmod 600 /home/swapfile
                            mkswap /home/swapfile
                            swapon /home/swapfile
                            echo "/home/swapfile none swap defaults 0 0" | tee -a /etc/fstab
                            echo "Swapfile criado com sucesso em /home/swapfile"
                        fi
                        echo "1" > "$S_SWAPFILE"
                        ;;
                    3)
                        return
                        ;;
                esac
                ;;
            3)
                echo "Remover swapfile:"
                echo ""
                echo "AVISO: Isto desativará e removerá o swapfile."
                read -p "Continuar? (s/n): " -n 1 resposta
                echo
                if [ "$resposta" = "s" ]; then
                    swapoff -a
                    
                    if [ -f /swapfile ]; then
                        rm -f /swapfile
                        sed -i '\|^/swapfile|d' /etc/fstab
                        echo "Swapfile /swapfile removido."
                    fi
                    
                    if [ -f /home/swapfile ]; then
                        rm -f /home/swapfile
                        sed -i '\|^/home/swapfile|d' /etc/fstab
                        echo "Swapfile /home/swapfile removido."
                    fi
                    
                    if [ -d /swap ] && [ -f /swap/swapfile ]; then
                        btrfs subvolume delete /swap 2>/dev/null || rm -rf /swap
                        sed -i '\|^/swap/swapfile|d' /etc/fstab
                        echo "Swapfile Btrfs /swap/swapfile removido."
                    fi
                    
                    if [ -d /home/swap ] && [ -f /home/swap/swapfile ]; then
                        btrfs subvolume delete /home/swap 2>/dev/null || rm -rf /home/swap
                        sed -i '\|^/home/swap/swapfile|d' /etc/fstab
                        echo "Swapfile Btrfs /home/swap/swapfile removido."
                    fi
                    
                    echo "Swap removido com sucesso."
                fi
                ;;
            4)
                read -p "Deseja remover o gerenciador de swapfile? (s/n): " -n 1 resposta
                echo
                if [ "$resposta" = "s" ]; then
                    rm -f "$S_SWAPFILE"
                    echo "Gerenciador de swapfile removido."
                fi
                ;;
            5)
                return
                ;;
        esac
    else
        if swapon --show | grep -q '.'; then
            echo "Status: SWAP EXISTENTE"
            echo "Swap já está habilitado no sistema."
            echo ""
            swapon --show
            echo ""
            echo "1) Registrar no gerenciador"
            echo "2) Criar novo swapfile"
            echo "3) Voltar"
            read -p "> " opt
            
            case $opt in
                1)
                    echo "1" > "$S_SWAPFILE"
                    echo "Swap registrado no gerenciador."
                    ;;
                2)
                    swapfile_install
                    ;;
                3)
                    return
                    ;;
            esac
        else
            echo "Status: NÃO INSTALADO"
            echo "Gerenciador de swapfile para criar e configurar arquivos de swap."
            echo "Swap melhora o desempenho do sistema com mais memória virtual."
            read -p "Configurar swapfile? (s/n): " -n 1 resposta
            echo
            
            if [ "$resposta" = "s" ]; then
                echo "Criar swapfile:"
                echo ""
                echo "1) Criar no diretório raiz (/) - 8GB"
                echo "2) Criar no diretório home (/home) - 8GB"
                echo "3) Personalizar tamanho e local"
                echo "4) Voltar"
                read -p "> " swap_opt
                
                case $swap_opt in
                    1)
                        echo "Criando swapfile de 8GB no diretório raiz..."
                        
                        if findmnt -n -o FSTYPE / | grep -q "btrfs"; then
                            echo "Sistema de arquivos Btrfs detectado..."
                            if [ ! -d /swap ]; then
                                btrfs subvolume create /swap
                            fi
                            btrfs filesystem mkswapfile --size 8g --uuid clear /swap/swapfile
                            swapon /swap/swapfile
                            echo "/swap/swapfile none swap defaults 0 0" | tee -a /etc/fstab
                            echo "Swapfile Btrfs criado com sucesso em /swap/swapfile"
                        else
                            echo "Criando swapfile tradicional..."
                            dd if=/dev/zero of=/swapfile bs=1G count=8 status=progress
                            chmod 600 /swapfile
                            mkswap /swapfile
                            swapon /swapfile
                            echo "/swapfile none swap defaults 0 0" | tee -a /etc/fstab
                            echo "Swapfile criado com sucesso em /swapfile"
                        fi
                        echo "1" > "$S_SWAPFILE"
                        echo "Swapfile criado e ativado com sucesso!"
                        ;;
                    2)
                        echo "Criando swapfile de 8GB no diretório home..."
                        
                        if findmnt -n -o FSTYPE /home | grep -q "btrfs"; then
                            echo "Sistema de arquivos Btrfs detectado..."
                            if [ ! -d /home/swap ]; then
                                btrfs subvolume create /home/swap
                            fi
                            btrfs filesystem mkswapfile --size 8g --uuid clear /home/swap/swapfile
                            swapon /home/swap/swapfile
                            echo "/home/swap/swapfile none swap defaults 0 0" | tee -a /etc/fstab
                            echo "Swapfile Btrfs criado com sucesso em /home/swap/swapfile"
                        else
                            echo "Criando swapfile tradicional..."
                            dd if=/dev/zero of=/home/swapfile bs=1G count=8 status=progress
                            chmod 600 /home/swapfile
                            mkswap /home/swapfile
                            swapon /home/swapfile
                            echo "/home/swapfile none swap defaults 0 0" | tee -a /etc/fstab
                            echo "Swapfile criado com sucesso em /home/swapfile"
                        fi
                        echo "1" > "$S_SWAPFILE"
                        echo "Swapfile criado e ativado com sucesso!"
                        ;;
                    3)
                        read -p "Tamanho do swapfile em GB (ex: 4, 8, 16): " swap_size
                        read -p "Localização (ex: /swapfile, /home/swapfile): " swap_location
                        
                        if [[ ! "$swap_size" =~ ^[0-9]+$ ]]; then
                            echo "Tamanho inválido."
                            read -p "Pressione Enter para continuar..."
                            return
                        fi
                        
                        if [ -z "$swap_location" ]; then
                            echo "Localização inválida."
                            read -p "Pressione Enter para continuar..."
                            return
                        fi
                        
                        echo "Criando swapfile de ${swap_size}GB em $swap_location..."
                        
                        dir=$(dirname "$swap_location")
                        if findmnt -n -o FSTYPE "$dir" | grep -q "btrfs"; then
                            echo "Sistema de arquivos Btrfs detectado..."
                            btrfs_dir="${dir}/swap-$(date +%s)"
                            btrfs subvolume create "$btrfs_dir"
                            btrfs filesystem mkswapfile --size ${swap_size}g --uuid clear "${btrfs_dir}/swapfile"
                            swapon "${btrfs_dir}/swapfile"
                            echo "${btrfs_dir}/swapfile none swap defaults 0 0" | tee -a /etc/fstab
                            echo "Swapfile Btrfs criado com sucesso em ${btrfs_dir}/swapfile"
                        else
                            echo "Criando swapfile tradicional..."
                            dd if=/dev/zero of="$swap_location" bs=1G count=$swap_size status=progress
                            chmod 600 "$swap_location"
                            mkswap "$swap_location"
                            swapon "$swap_location"
                            echo "$swap_location none swap defaults 0 0" | tee -a /etc/fstab
                            echo "Swapfile criado com sucesso em $swap_location"
                        fi
                        echo "1" > "$S_SWAPFILE"
                        echo "Swapfile criado e ativado com sucesso!"
                        ;;
                    4)
                        return
                        ;;
                esac
            fi
        fi
    fi
    
    read -p "Pressione Enter para continuar..."
}

distrobox_handler_install() {
    clear
    echo "=== Distrobox Command Handler ==="
    
    if [ -f "$S_DISTROBOX_HANDLER" ]; then
        echo "Status: INSTALADO"
        echo "1) Verificar instalação"
        echo "2) Atualizar configuração"
        echo "3) Remover"
        echo "4) Voltar"
        read -p "> " opt
        
        case $opt in
            1)
                echo "Verificando instalação do Distrobox Command Handler..."
                echo ""
                
                local handler_dir="$HOME/.local/distrobox-handler"
                
                if [ -d "$handler_dir" ]; then
                    echo "Diretório do handler: EXISTE ($handler_dir)"
                    
                    if [ -f "$handler_dir/command_not_found_handle" ]; then
                        echo "Handler Bash: INSTALADO"
                    else
                        echo "Handler Bash: NÃO INSTALADO"
                    fi
                    
                    if [ -f "$handler_dir/zsh_command_not_found_handler" ]; then
                        echo "Handler Zsh: INSTALADO"
                    else
                        echo "Handler Zsh: NÃO INSTALADO"
                    fi
                else
                    echo "Diretório do handler: NÃO EXISTE"
                fi
                
                echo ""
                echo "Integrações:"
                
                if [ -f "/etc/bash.bashrc.d/99-distrobox-cnf" ]; then
                    echo "Bash system-wide: INSTALADO"
                else
                    echo "Bash system-wide: NÃO INSTALADO"
                fi
                
                if [ -f "/etc/zsh/zshrc.d/99-distrobox-cnf.zsh" ]; then
                    echo "Zsh system-wide: INSTALADO"
                else
                    echo "Zsh system-wide: NÃO INSTALADO"
                fi
                
                if grep -q "distrobox-handler" "$HOME/.bashrc" 2>/dev/null; then
                    echo "Bash user: INSTALADO"
                else
                    echo "Bash user: NÃO INSTALADO"
                fi
                
                if grep -q "distrobox-handler" "$HOME/.zshrc" 2>/dev/null; then
                    echo "Zsh user: INSTALADO"
                else
                    echo "Zsh user: NÃO INSTALADO"
                fi
                
                if [ -f "/etc/profile.d/distrobox-host-aliases.sh" ]; then
                    echo "Aliases: INSTALADO"
                else
                    echo "Aliases: NÃO INSTALADO"
                fi
                ;;
            2)
                echo "Atualizando configuração do Distrobox Command Handler..."
                
                local handler_dir="$HOME/.local/distrobox-handler"
                mkdir -p "$handler_dir"
                
                cat > "$handler_dir/command_not_found_handle" << 'EOF'
#!/bin/bash
# Distrobox Command-Not-Found Handler
# Automatically executes commands on host if not found in container
command_not_found_handle() {
    local cmd="$1"
    shift
    local args="$@"
    
    if ! command -v distrobox-host-exec >/dev/null 2>&1; then
        echo "bash: $cmd: command not found" >&2
        return 127
    fi
    
    if distrobox-host-exec which "$cmd" >/dev/null 2>&1; then
        echo "Command '$cmd' not found in container, executing on host..." >&2
        exec distrobox-host-exec "$cmd" "$@"
    else
        echo "bash: $cmd: command not found" >&2
        return 127
    fi
}
EOF
                
                cat > "$handler_dir/zsh_command_not_found_handler" << 'EOF'
#!/bin/bash
# Distrobox ZSH Command-Not-Found Handler
zsh_command_not_found_handler() {
    local cmd="$1"
    shift
    local args="$@"
    
    if ! command -v distrobox-host-exec >/dev/null 2>&1; then
        echo "zsh: command not found: $cmd" >&2
        return 127
    fi
    
    if distrobox-host-exec which "$cmd" >/dev/null 2>&1; then
        echo "Command '$cmd' not found in container, executing on host..." >&2
        exec distrobox-host-exec "$cmd" "$@"
    else
        echo "zsh: command not found: $cmd" >&2
        return 127
    fi
}
EOF
                
                chmod +x "$handler_dir/command_not_found_handle"
                chmod +x "$handler_dir/zsh_command_not_found_handler"
                
                mkdir -p /etc/bash.bashrc.d
                cat > /etc/bash.bashrc.d/99-distrobox-cnf << 'EOF'
# Distrobox Command-Not-Found Handler Integration
if [ -f "$HOME/.local/distrobox-handler/command_not_found_handle" ]; then
    source "$HOME/.local/distrobox-handler/command_not_found_handle"
fi
EOF
                
                mkdir -p /etc/zsh/zshrc.d
                cat > /etc/zsh/zshrc.d/99-distrobox-cnf.zsh << 'EOF'
# Distrobox Command-Not-Found Handler Integration for ZSH
if [ -f "$HOME/.local/distrobox-handler/zsh_command_not_found_handler" ]; then
    source "$HOME/.local/distrobox-handler/zsh_command_not_found_handler"
fi
EOF
                
                if [ -f "$HOME/.bashrc" ] && ! grep -q "distrobox-handler/command_not_found_handle" "$HOME/.bashrc"; then
                    cat >> "$HOME/.bashrc" << 'EOF'

# Distrobox Command-Not-Found Handler Integration
if [ -f "$HOME/.local/distrobox-handler/command_not_found_handle" ]; then
    source "$HOME/.local/distrobox-handler/command_not_found_handle"
fi
EOF
                fi
                
                if [ -f "$HOME/.zshrc" ] && ! grep -q "distrobox-handler/zsh_command_not_found_handler" "$HOME/.zshrc"; then
                    cat >> "$HOME/.zshrc" << 'EOF'

# Distrobox Command-Not-Found Handler Integration
if [ -f "$HOME/.local/distrobox-handler/zsh_command_not_found_handler" ]; then
    source "$HOME/.local/distrobox-handler/zsh_command_not_found_handler"
fi
EOF
                fi
                
                cat > /etc/profile.d/distrobox-host-aliases.sh << 'EOF'
# Common host command aliases for distrobox containers
alias xdg-open='distrobox-host-exec xdg-open'
alias nautilus='distrobox-host-exec nautilus'
alias dolphin='distrobox-host-exec dolphin'
alias thunar='distrobox-host-exec thunar'
alias htop='distrobox-host-exec htop'
alias lscpu='distrobox-host-exec lscpu'
alias lsusb='distrobox-host-exec lsusb'
alias lspci='distrobox-host-exec lspci'
alias nmcli='distrobox-host-exec nmcli'
alias nmtui='distrobox-host-exec nmtui'
alias flatpak='distrobox-host-exec flatpak'
alias snap='distrobox-host-exec snap'
alias gedit='distrobox-host-exec gedit'
alias kate='distrobox-host-exec kate'
alias firefox='distrobox-host-exec firefox'
alias chromium='distrobox-host-exec chromium'
alias google-chrome='distrobox-host-exec google-chrome'
EOF
                
                echo "Configuração atualizada com sucesso!"
                echo "Reinicie o terminal ou execute: source ~/.bashrc"
                ;;
            3)
                read -p "Deseja remover o Distrobox Command Handler? (s/n): " -n 1 resposta
                echo
                if [ "$resposta" = "s" ]; then
                    echo "Removendo Distrobox Command Handler..."
                    
                    rm -rf "$HOME/.local/distrobox-handler" 2>/dev/null
                    
                    rm -f /etc/bash.bashrc.d/99-distrobox-cnf 2>/dev/null
                    rm -f /etc/zsh/zshrc.d/99-distrobox-cnf.zsh 2>/dev/null
                    rm -f /etc/profile.d/distrobox-host-aliases.sh 2>/dev/null
                    
                    if [ -f "$HOME/.bashrc" ]; then
                        sed -i '/# Distrobox Command-Not-Found Handler Integration/,+3d' "$HOME/.bashrc"
                    fi
                    
                    if [ -f "$HOME/.zshrc" ]; then
                        sed -i '/# Distrobox Command-Not-Found Handler Integration/,+3d' "$HOME/.zshrc"
                    fi
                    
                    rm -f "$S_DISTROBOX_HANDLER"
                    echo "Distrobox Command Handler removido com sucesso!"
                    echo "Reinicie o terminal para aplicar."
                fi
                ;;
            4)
                return
                ;;
        esac
    else
        echo "Status: NÃO INSTALADO"
        echo "Distrobox Command Handler permite executar comandos do host"
        echo "automaticamente quando não encontrados em containers Distrobox."
        read -p "Instalar Distrobox Command Handler? (s/n): " -n 1 resposta
        echo
        
        if [ "$resposta" = "s" ]; then
            echo "Instalando Distrobox Command Handler..."
            
            local handler_dir="$HOME/.local/distrobox-handler"
            mkdir -p "$handler_dir"
            
            cat > "$handler_dir/command_not_found_handle" << 'EOF'
#!/bin/bash
# Distrobox Command-Not-Found Handler
# Automatically executes commands on host if not found in container
command_not_found_handle() {
    local cmd="$1"
    shift
    local args="$@"
    
    if ! command -v distrobox-host-exec >/dev/null 2>&1; then
        echo "bash: $cmd: command not found" >&2
        return 127
    fi
    
    if distrobox-host-exec which "$cmd" >/dev/null 2>&1; then
        echo "Command '$cmd' not found in container, executing on host..." >&2
        exec distrobox-host-exec "$cmd" "$@"
    else
        echo "bash: $cmd: command not found" >&2
        return 127
    fi
}
EOF
            
            cat > "$handler_dir/zsh_command_not_found_handler" << 'EOF'
#!/bin/bash
# Distrobox ZSH Command-Not-Found Handler
zsh_command_not_found_handler() {
    local cmd="$1"
    shift
    local args="$@"
    
    if ! command -v distrobox-host-exec >/dev/null 2>&1; then
        echo "zsh: command not found: $cmd" >&2
        return 127
    fi
    
    if distrobox-host-exec which "$cmd" >/dev/null 2>&1; then
        echo "Command '$cmd' not found in container, executing on host..." >&2
        exec distrobox-host-exec "$cmd" "$@"
    else
        echo "zsh: command not found: $cmd" >&2
        return 127
    fi
}
EOF
            
            chmod +x "$handler_dir/command_not_found_handle"
            chmod +x "$handler_dir/zsh_command_not_found_handler"
            
            mkdir -p /etc/bash.bashrc.d
            cat > /etc/bash.bashrc.d/99-distrobox-cnf << 'EOF'
# Distrobox Command-Not-Found Handler Integration
if [ -f "$HOME/.local/distrobox-handler/command_not_found_handle" ]; then
    source "$HOME/.local/distrobox-handler/command_not_found_handle"
fi
EOF
            
            mkdir -p /etc/zsh/zshrc.d
            cat > /etc/zsh/zshrc.d/99-distrobox-cnf.zsh << 'EOF'
# Distrobox Command-Not-Found Handler Integration for ZSH
if [ -f "$HOME/.local/distrobox-handler/zsh_command_not_found_handler" ]; then
    source "$HOME/.local/distrobox-handler/zsh_command_not_found_handler"
fi
EOF
            
            if [ -f "$HOME/.bashrc" ]; then
                cat >> "$HOME/.bashrc" << 'EOF'

# Distrobox Command-Not-Found Handler Integration
if [ -f "$HOME/.local/distrobox-handler/command_not_found_handle" ]; then
    source "$HOME/.local/distrobox-handler/command_not_found_handle"
fi
EOF
            fi
            
            if [ -f "$HOME/.zshrc" ]; then
                cat >> "$HOME/.zshrc" << 'EOF'

# Distrobox Command-Not-Found Handler Integration
if [ -f "$HOME/.local/distrobox-handler/zsh_command_not_found_handler" ]; then
    source "$HOME/.local/distrobox-handler/zsh_command_not_found_handler"
fi
EOF
            fi
            
            cat > /etc/profile.d/distrobox-host-aliases.sh << 'EOF'
# Common host command aliases for distrobox containers
alias xdg-open='distrobox-host-exec xdg-open'
alias nautilus='distrobox-host-exec nautilus'
alias dolphin='distrobox-host-exec dolphin'
alias thunar='distrobox-host-exec thunar'
alias htop='distrobox-host-exec htop'
alias lscpu='distrobox-host-exec lscpu'
alias lsusb='distrobox-host-exec lsusb'
alias lspci='distrobox-host-exec lspci'
alias nmcli='distrobox-host-exec nmcli'
alias nmtui='distrobox-host-exec nmtui'
alias flatpak='distrobox-host-exec flatpak'
alias snap='distrobox-host-exec snap'
alias gedit='distrobox-host-exec gedit'
alias kate='distrobox-host-exec kate'
alias firefox='distrobox-host-exec firefox'
alias chromium='distrobox-host-exec chromium'
alias google-chrome='distrobox-host-exec google-chrome'
EOF
            
            echo "1" > "$S_DISTROBOX_HANDLER"
            echo "Distrobox Command Handler instalado com sucesso!"
            echo ""
            echo "Recursos instalados:"
            echo "  • Handler para Bash e Zsh"
            echo "  • Integração system-wide"
            echo "  • Aliases para comandos comuns"
            echo ""
            echo "Reinicie o terminal ou execute: source ~/.bashrc"
        fi
    fi
    
    read -p "Pressione Enter para continuar..."
}

main() {
    while true; do
        clear
        echo "=== Menu Principal ==="
        echo "1) Shader Booster"
        echo "2) Desktop Environment"
        echo "3) LucidGlyph"
        echo "4) AppArmor"
        echo "5) UFW Firewall"
        echo "6) EarlyOOM"
        echo "7) DNSMasq"
        echo "8) Nix Packages"
        echo "9) Chaotic AUR"
        echo "10) Docker"
        echo "11) Tailscale"
        echo "12) Fisher (Fish Shell)"
        echo "13) Starship Prompt"
        echo "14) Oh My Bash"
        echo "15) Flathub"
        echo "16) Yay AUR Helper"
        echo "17) Lazyman / LazyVim"
        echo "18) CPU Ondemand Governor"
        echo "19) Ananicy-cpp (Auto Nice)"
        echo "20) Arch Secure Boot (sbctl)"
        echo "21) Btrfs Assistant"
        echo "22) CachyOS Configs"
        echo "23) HW Acceleration Flatpak"
        echo "24) Swapfile Manager"
        echo "25) Distrobox Command Handler"
        echo "26) Sair"
        read -p "> " opcao
        
        case $opcao in
            1) shader_booster ;;
            2) desktop_environment ;;
            3) lucidglyph ;;
            4) apparmor ;;
            5) ufw_firewall ;;
            6) earlyoom ;;
            7) dnsmasq ;;
            8) nix_packages ;;
            9) chaotic_aur ;;
            10) docker_install ;;
            11) tailscale_install ;;
            12) fisher_install ;;
            13) starship_install ;;
            14) ohmybash_install ;;
            15) flathub_install ;;
            16) yay_install ;;
            17) lazyman_install ;;
            18) cpu_ondemand ;;
            19) ananicy_install ;;
            20) archsb_install ;;
            21) btrfs_assistant_install ;;
            22) cachyconfs_install ;;
            23) hwaccel_flatpak_install ;;
            24) swapfile_install ;;
            25) distrobox_handler_install ;;
            26) exit 0 ;;
            *) ;;
        esac
    done
}

main
