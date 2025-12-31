git clone https://github.com/RENAN029/jq.git

cd jq

chmod +x b.sh

./b.sh

sudo pacman -Scc smartmontools iwd

sudo pacman -S github-cli httpie

sudo pacman -Syu $(pacman -Qnq) 

sudo pacman -Rsnu $(pacman -Qdtq) 
