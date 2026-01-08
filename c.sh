set -e

sudo pacman -S --noconfirm noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-noto-nerd noto-fonts-extra ttf-jetbrains-mono
sudo pacman -S --noconfirm ffmpeg gst-plugins-ugly gst-plugins-good gst-plugins-base gst-plugins-bad gst-libav gstreamer
sudo pacman -S --noconfirm cosmic-session cosmic-terminal cosmic-files cosmic-store cosmic-wallpapers xdg-user-dirs croc
sudo pacman -S --noconfirm gdu

nvidia-open intel-ucode neovim fastfetch btop ufw fwupd flatpak yt-dlp aria2 
 
sudo pacman -Syu --noconfirm 
sudo pacman -Scc --noconfirm
echo "sudo pacman -S nix yay gamescope distrobox python-pip rustup ananicy-cpp zerotier-one tailscale mise pnpm docker"   
cd ..
rm -rf jq
