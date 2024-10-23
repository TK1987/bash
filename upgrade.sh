#!/usr/bin/sudo /bin/bash

### HAUPTPROGRAMM ###
	main() {
    if dpkg -l | grep -qE "^[a-zA-Z][A-Z]"; then
      if ! repair; then
        return 1
      fi
    fi

		if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
			echo -e "\e[1;31mDerzeit besteht keine Internetverbindung.\e[0;0m"
		elif pgrep -a apt >/dev/null; then
      echo -e "\e[1;31mEs läuft bereits ein APT-Prozess.\e[0;0m"
		elif pgrep -a dpkg >/dev/null; then
      echo -e "\e[1;31mEs läuft noch ein DPKG-Prozess.\e[0;0m"
		else
      aptUpgrade
		fi
	}

### FUNKTIONEN ###
	aptUpgrade() {
		apt-get -y update
		echo "Installiere Updates... "
		if ! apt-get -y full-upgrade; then
      if ! repair; then
        return 1
      else
        /bin/bash $(realpath "${BASH_SOURCE[0]}")
      fi
    fi
		echo -e "\e[1;33mEntferne nicht mehr benötigte Pakete... \e[0;0m"
		apt -y autoremove
		if [ -f /var/run/reboot-required ]; then
			echo -e "\e[93mBitte starten sie den Computer neu.\e[0;0m"
		else
      echo -e "\e[93mIhr Computer ist aktuell, kein Neustart nötig.\e[0;0m"
    fi
	}

  repair(){
    ErrSt=0
    echo 
    if ! dpkg --configure -a 2>/dev/null;then ErrSt=1; fi
    if ! sudo apt-get install --fix-broken -y 2>/dev/null; then ErrSt=1; else ErrSt=0; fi
    if [ $ErrSt != 0 ]; then
      echo -E "\e[31mDas Paketsystem ist beschädigt und konnte nicht repariert werden.\e[0m\nDefekte Pakete: "
      dpkg -l | awk '$1 ~ "^[a-zA-Z][A-Z]" {print "  " $2}'
      return 1
    fi
  }

### RUN ###
  main
