#!/bin/bash

TXTBIPINK='\033[1;95m'
TXTNC='\033[0m'

## Remove swap volume, add second drive and resize root
VG='vgkubuntu'
SSD2='nvme1n1'

echo -e "${TXTBPINK}Disable swap_1 volume, remove volume, then remove reference in /etc/fstab..."
sudo swapoff /dev/${VG}/swap_1
sudo lvremove /dev/${VG}/swap_1 -y
sudo sed "\@swap_1@d" /etc/fstab

if ls /dev | grep ${SSD2} > /dev/null 2>&1
then
    sudo pvcreate /dev/${SSD2} -y
    sudo vgextend ${VG} /dev/${SSD2} -ff -y
fi

sudo lvm lvextend -l +100%FREE /dev/${VG}/root -y
sudo resize2fs /dev/${VG}/root -y

## Add nvidia stuff to kernel options.
echo -e "${TXTBPINK}Add NVIDIA stuff to kernel options, then update GRUB..."
sudo sed -i 's/quiet splash/quiet splash nvidia-drm.modeset=0 nvidia.NVreg_RegistryDwords=EnableBrightnessControl=1/g' /etc/default/grub
sudo update-grub

echo -e "${TXTBPINK}Copying various system files, setting permissions, etc..."
## Copy Lenovo LEGION specific scripts to /usr/local/bin.
sudo cp -avr files/scripts/* /usr/local/bin/
sudo chown -R root:root /usr/local/bin/*
sudo chmod +x /usr/local/bin/*

## Copy X11 files to /etc/X11/xorg.conf.d.
sudo cp -avr files/xorg/* /etc/X11/xorg.conf.d/
sudo chown -R root:root /etc/X11/xorg.conf.d/*

## Copy modprobe files to /etc/modprobe.d.
sudo cp -avr files/modprobe/* /etc/modprobe.d/
sudo chown -R root:root /etc/modprobe.d/*

## Copy systemd files to /etc/systemd.
sudo cp -avr files/systemd/* /etc/systemd/
sudo chown -R root:root /etc/systemd/*

## Copy udev files to /etc/udev/rules.d.
sudo cp -avr files/udev/* /etc/udev/rules.d/
sudo chown -R root:root /etc/udev/rules.d/*

## Add graphics-drivers PPA.
echo -e "${TXTBIPINK}Adding graphics-drivers PPA...\n${TXTNC}"
sudo add-apt-repository ppa:graphics-drivers/ppa -y && sudo apt dist-upgrade -y

## Add OpenRGB PPA.
sudo add-apt-repository ppa:thopiekar/openrgb -y && sudo apt install openrgb -y

## Install lowlatency kernel.
echo -e "${TXTBIPINK}Installing lowlatency kernel...\n${TXTNC}"
sudo apt install linux-image-lowlatency linux-modules-nvidia-525-lowlatency -y

## Install packages.
echo -e "${TXTBIPINK}Installing packages...\n${TXTNC}"
for pkg in $(cat pkgs.txt)
do
    PKGS+=" ${pkg}"
done

sudo apt install ${PKGS} -y

## Copy Vim configs to /etc/vim
sudo cp -avr files/vim/* /etc/vim/
sudo chown -R root:root /etc/vim/*

## Add Opera (Stable) repo and install Opera.
echo -e "${TXTBPINK}Adding Opera (Stable) repo, then installing Opera..."
echo "deb http://deb.opera.com/opera-stable/ stable non-free" | sudo tee -a /etc/apt/sources.list.d/opera-stable.repo
wget -O - https://deb.opera.com/archive.key | sudo apt-key add -
sudo apt update
sudo apt install opera-stable

## Add repo for Prism Launcher and Discord; install packages.
echo -e "${TXTBIPINK}Adding repo for Prism Launcher and Discord, and installing packages...${TXTNC}"
curl -q 'https://proget.makedeb.org/debian-feeds/prebuilt-mpr.pub' | gpg --dearmor | sudo tee /usr/share/keyrings/prebuilt-mpr-archive-keyring.gpg 1> /dev/null
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/prebuilt-mpr-archive-keyring.gpg] https://proget.makedeb.org prebuilt-mpr $(lsb_release -cs)" | sudo tee /etc/apt/sources.list.d/prebuilt-mpr.list
sudo apt update
sudo apt install discord prismlauncher -y

## Add makedeb.
wget -qO - 'https://proget.makedeb.org/debian-feeds/makedeb.pub' | gpg --dearmor | sudo tee /usr/share/keyrings/makedeb-archive-keyring.gpg 1> /dev/null
echo 'deb [signed-by=/usr/share/keyrings/makedeb-archive-keyring.gpg arch=all] https://proget.makedeb.org/ makedeb main' | sudo tee /etc/apt/sources.list.d/makedeb.list
sudo apt update

## Add Una.
sudo mkdir -p /etc/una/config
bash <(curl -fsL https://github.com/AFK-OS/una/raw/main/install.sh)

## Install Element (matrix.org client).
echo -e "${TXTBPINK}Adding Element repo and installing the Element client...${TXTNC}"
sudo wget -O /usr/share/keyrings/element-io-archive-keyring.gpg https://packages.element.io/debian/element-io-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/element-io-archive-keyring.gpg] https://packages.element.io/debian/ default main" | sudo tee /etc/apt/sources.list.d/element-io.list
sudo apt update
sudo apt install element-desktop

## Install Pacstall.
sudo bash -c "$(curl -fsSL https://git.io/JsADh || wget -q https://git.io/JsADh -O -)"

## Set shells to zsh.
echo -e "${TXTBIPINK}Setting shell to zsh for root and $USER...${TXTNC}"
sudo usermod -s /bin/zsh root && sudo usermod -s /bin/zsh $USER

## Install Oh My ZSH! for user and root.
echo -e "${TXTBPINK}Installing Oh My ZSH! for ${USER} and root...${TXTNC}"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
sudo sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

## Install Starship for user and root.
echo -e "${TXTBPINK}Installing Starship for ${USER} and root..."
git clone https://github.com/starship/starship
DPPWD=${PWD}
starship/install/install.sh -y

echo 'eval "$(starship init zsh)"' >> ~/.zshrc
sudo cp /home/${USER}/.zshrc /root
sudo chown -R root:root /root/.zshrc

## Cleanup, remove unnecessary packages, like postfix
sudo apt --purge remove postfix
sudo apt --purge autoremove

## Time to reboot!
shutdown -r now
