#!/bin/bash

# Check if the script is being run as root, and if not, re-run it with sudo
if [ "$EUID" -ne 0 ]; then
  exec sudo "$0" "$@"
fi

# Function to add a line to /etc/security/pam_env.conf if it's not contained
add_line_to_pam_env() {
  local line="$1"
  if grep -Fxq "$line" /etc/security/pam_env.conf; then
    echo "Line already exists in /etc/security/pam_env.conf. No changes needed."
  else
    echo "$line" | sudo tee -a /etc/security/pam_env.conf > /dev/null
    echo "Line added to /etc/security/pam_env.conf. You must log out and in for changes to take effect."
    logout_required=true
  fi
}

# Initialize the variable to keep track of logout requirement
logout_required=false

# Log "Updating/upgrading packages" and run updates/upgrades silently
echo "Updating/upgrading packages (this may take a while if this is the first time this is being executed)"
apt-get update -y > /dev/null
apt-get upgrade -y > /dev/null

# Prompt for installing fingerprint reader
read -p "Do you want to set up the fingerprint reader? (Y/N): " fingerprint_choice
if [[ "$fingerprint_choice" =~ ^[Yy]$ ]]; then
  apt-get install fprintd libpam-fprintd
  # Software for setting up fingerprint reader
  add-apt-repository ppa:uunicorn/open-fprintd
  add-apt-repository ppa:uunicorn/open-fprintd
  # Select it as an acceptable source
  pam-auth-update
fi

# Prompt for installing GameMaker
read -p "Do you want to install Steam and GameMaker? (Y/N): " gamemaker_choice
if [[ "$gamemaker_choice" =~ ^[Yy]$ ]]; then
  # Install Steam, GameMaker & Dependencies
  sudo apt-get install build-essential openssh-server clang libssl-dev libxrandr-dev libxxf86vm-dev libopenal-dev libgl1-mesa-dev libglu1-mesa-dev zlib1g-dev libcurl4-openssl-dev ffmpeg
  cd ~/Downloads
  curl https://repo.steampowered.com/steamrt-images-scout/snapshots/latest-steam-client-general-availability/com.valvesoftware.SteamRuntime.Sdk-amd64,i386-scout-sysroot.tar.gz | sudo tar -xzf - -C /opt/steam-runtime/
  wget https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage
  sudo install -m 0755 linuxdeploy-x86_64.AppImage /usr/local/bin/linuxdeploy
  rm linuxdeploy-x86_64.AppImage
  wget https://gms.yoyogames.com/GameMaker-Beta-2023.800.0.377.deb
  sudo dpkg -i GameMaker-Beta-2023.800.0.377.deb
  rm GameMaker-Beta-2023.800.0.377.deb
fi

# Prompt for setting up touchscreen
read -p "Do you want to set up touchscreen? (Y/N): " touchscreen_choice
if [[ "$touchscreen_choice" =~ ^[Yy]$ ]]; then
  line="MOZ_USE_XINPUT2 DEFAULT=1"
  add_line_to_pam_env "$line"
  logout_required=true
fi

# Prompt to log out if necessary
if [ "$logout_required" = true ]; then
  echo "One or more of your changes requires logout to take affect, please log out manually to apply the changes."
fi

echo "
ALL DONE!"
# End of the script
