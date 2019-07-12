#!/usr/bin/sudo /bin/bash

### HAUPTPROGRAMM ###
	main() {
		if ! ping -c 1 8.8.8.8 >/dev/null 2>&1
			then echo -e "\e[1;31mDerzeit besteht keine Internetverbindung.\e[0;0m"
			elif pgrep -a apt >/dev/null
				then echo -e "\e[1;31mEs läuft bereits ein APT-Prozess.\e[0;0m"
			else aptUpgrade
			fi
		}

### FUNKTIONEN ###

	aptUpgrade() {
		apt -y update
		echo "Installiere Updates... "
		apt -y full-upgrade
		if [ $? != 0 ]
			then
				echo -e "\e[1;31mDas Paketsystem ist beschädigt. Versuche Reparatur...\e[0;0m"
				dpkg --configure -a
				apt-get -y --fix-broken install
				apt -y autoremove --purge
				apt clean
				apt -y full-upgrade
				if [ $? = 0 ]
					then echo -e "\e[1;32mReparatur war erfolgreich.\e[0;0m"
					else
						echo -e "\e[1;31mPaketsystem konnte nicht repariert werden!\e[0;0m"
						export -f zWarn	
						su $(users|cut -d' ' -f1) -c 'zWarn'
					return 1
					fi
			else echo -e "\e[1;32mPakete wurden erfolgreich aktualisiert.\e[0;0m"
			fi
		echo -e "\e[1;33mEntferne nicht mehr benötigte Pakete... \e[0;0m"
		apt -y autoremove
		if [ -f /var/run/reboot-required ]
			then echo -e  "\e[1;33mBitte starten sie den Computer neu.\e[0;0m"
			else echo -e "\e[1;33mIhr Computer ist aktuell, kein Neustart nötig.\e[0;0m"
			fi
		}

	zWarn() {
		zenity --warning --width=300 --text='Das Paketsystem ist beschädigt und konnte nicht repariert werden!' --display=:0.0 2>/dev/null
		}

### RUN ###
main
