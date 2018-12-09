#!/usr/bin/env bash
set -e
if [ ! -z "$PASSWORD" ]; then
  if [ ! -z "$USER" ]; then
    userdel -r rstudio
    useradd $USER
	usermod -a -G ruser $USER
    echo "$USER:$PASSWORD" | chpasswd
	mkdir -p /home/$USER/.R/rstudio/keybindings
    cp /rstudio-server/keybindings/*.json /home/$USER/.R/rstudio/keybindings/
    mkdir -p /home/$USER/.rstudio/monitored/user-settings 
    cp /rstudio-server/user-settings/* /home/$USER/.rstudio/monitored/user-settings/
    cp /rstudio-server/benchmark.R /home/$USER
    chown -R $USER: /home/$USER/
  else
    echo "rstudio:$PASSWORD" | chpasswd
  fi
fi

exec "$@"

