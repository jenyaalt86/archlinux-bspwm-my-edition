#!/bin/bash


USERNAME="$(whoami)"


function func_install() {
    if pacman -Qi $1 &> /dev/null
	then
		tput setaf 2
  		echo "###############################################################################"
  		echo ":: The package "$1" is already installed"
        echo "###############################################################################"
		tput sgr0    
	else
        tput setaf 3
        echo "###############################################################################"
        echo ":: Installing package "  $1 
        echo "###############################################################################"
        tput sgr0
        $2
	fi
}


function welcome() {
    echo "==================="    
    echo ":: Install bwpwm ::"    
    echo "==================="    
    echo
}


function pre_install_config() {    
    echo "Configure reflector"
    sudo reflector -c Belarus -c Poland -c Latvia -c Lithuania -c Russia -c Ukrain -a 12 -p https -p http --save /etc/pacman.d/mirrorlist

    echo "Enabling reflector:"
    sudo systemctl enable reflector.service        

    echo "Update and upgrade:"
    sudo pacman -Syyuu
}


function install_video_drivers() {
    MACHINE="$(hostnamectl status)"
    if [[ $MACHINE == *"Virtualization:"* ]]
    then
        echo "Installing virtualbox drivers"
        func_install "virtualbox-guest-utils" "sudo pacman -S virtualbox-guest-utils"
        func_install "xf86-video-fbdev" "sudo pacman -S xf86-video-fbdev"
    else
        echo "Installing nvidia drivers and utils"
        func_install "nvidia" "sudo pacman -S nvidia"
        func_install "nvidia-utils" "sudo pacman -S nvidia-utils"        
    fi
}


function install_yay_aur_helper() {
    if ! pacman -Qi yay-git &> /dev/null
    then 
        echo "Installing yay AUR helper:"
        cd %HOME
        git clone https://aur.archlinux.org/yay-git.git
        sudo chown -R ${USERNAME}:${USERNAME} ./yay-git
        cd yay-git
        makepkg -si
        cd ..
        rm -rf yay yay-git
    fi
}


function install_packages(){
    while IFS= read -r PACKAGE
        do
            if ! [[ "$PACKAGE" == *"#"* ]]
            then 
                INSTALL_SCRIPT=$(echo "sudo pacman -S --noconfirm --needed $PACKAGE ")            
                func_install "$PACKAGE" "$INSTALL_SCRIPT"
            fi
    done < regular_packages.txt

    while IFS= read -r PACKAGE
        do
            if ! [[ "$PACKAGE" == *"#"* ]]
            then 
                INSTALL_SCRIPT=$(echo "yay -S --noconfirm --needed $PACKAGE ")
                func_install "$PACKAGE" "$INSTALL_SCRIPT"        
            fi
    done < aur_packages.txt    
}


function post_install_config() {
    echo "Enabling NetworkManager:"
    sudo systemctl enable NetworkManager.service

    echo "Enabling bluetooth:"
    sudo systemctl enable bluetooth.service     

    echo "Clean cache:"
    sudo fc-cache -f -v    
}


function copy_config_files() {
    echo "Copy configuration files:"
    CURRENT_DIR=".config/*"
    TARGET_DIR="~/.config/"
    mkdir -p $TARGET_DIR
    cp -R $CURRENT_DIR $TARGET_DIR

    chmod -R +x ~/.config/bspwm
    chmod -R +x ~/.config/polybar

    echo "Copy fonts:"
    sudo mkdir -p /usr/share/fonts/TTF/
    sudo cp -R ./fonts/* /usr/share/fonts/TTF/

    echo "Config IBUS"
    sudo cp -R .environment /etc/environment        
}


function complete_message() {    
    echo "====================================================="    
    echo ":: Successfully installed, You can reboot now ::"    
    echo "=====================================================" 
}


welcome
pre_install_config
install_video_drivers
install_yay_aur_helper
install_packages
post_install_config
copy_config_files
complete_message
