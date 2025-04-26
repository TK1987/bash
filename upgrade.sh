#!/bin/bash

### HAUPTPROGRAMM ###
	main() {
    if dpkg -l | grep -qE "^[a-zA-Z][A-Z]"; then
      if ! repair; then
        return 1
      fi
    fi

		if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
      1>&2 printf "\e[91m%s\e[0m\n" "Derzeit besteht keine Internetverbindung."
		elif pgrep -a apt >/dev/null; then
      1>&2 printf "\e[91m%s\e[0m\n" "Es läuft bereits ein APT-Prozess."
		elif pgrep -a dpkg >/dev/null; then
      1>&2 printf "\e[91m%s\e[0m\n" "Es läuft noch ein DPKG-Prozess.\e[0;0m"
		else
      aptUpgrade
		fi
	}

### FUNKTIONEN ###
	aptUpgrade() {
		apt-get -y update
  	1>&2 printf "\e[93m%s\e[0m\n" "Updates werden installiert. "
		if ! apt-get -y full-upgrade; then
      if ! repair; then
        return 1
      else
        /bin/bash $(realpath "${BASH_SOURCE[0]}")
      fi
    fi
    1>&2 printf "\e[93m%s\e[0m\n" "Obsolete Pakete werden entfernt. "
		apt-get -y autoremove
		if [ -f /var/run/reboot-required ]; then
      1>&2 printf "\e[93m%s\e[0m\n" "Bitte starten sie den Computer neu. "
		else
      1>&2 printf "\e[93m%s\e[0m\n" "Ihr Computer ist aktuell, kein Neustart nötig. "  
    fi
	}

  repair(){
    ErrSt=0
    echo 
    if ! dpkg --configure -a 2>/dev/null;then ErrSt=1; fi
    if ! sudo apt-get install --fix-broken -y 2>/dev/null; then ErrSt=1; else ErrSt=0; fi
    if [ $ErrSt != 0 ]; then
      1>&2 printf "\e[91m%s\e[0m\n" "Das Paketsystem ist beschädigt und konnte nicht repariert werden. "
      echo -e "\nDefekte Pakete: "
      dpkg -l | awk '$1 ~ "^[a-zA-Z][A-Z]" {print "  " $2}'
      return 1
    fi
  }

### RUN ###
  if [ "$EUID" != "0" ];then
    printf '\e[93m%s\e[0m\n' "WARNING: This Script must be run as root."
    exit
  fi
  main
