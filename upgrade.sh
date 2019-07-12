#!/usr/bin/sudo /bin/bash
su $(users|cut -d' ' -f1) -c 'notify-send -i /usr/share/icons/gnome/48x48/status/dialog-warning.png "Warnung" "Ihr Paketsystem ist beschädigt und konnte nicht repariert werden!" -t 0'

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
					else echo -e "Paketsystem konnte nicht repariert werden."
					export DISPLAY=:0
					su $(users|cut -d' ' -f1) -c 'notify-send -i /usr/share/icons/gnome/48x48/status/dialog-warning.png "Warnung" "Ihr Paketsystem ist beschädigt und konnte nicht repariert werden!" -t 0'
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

### HAUPTPROGRAMM ###
	if ! ping -c 1 8.8.8.8 >/dev/null 2>&1
		then echo -e "\e[1;31mDerzeit besteht keine Internetverbindung.\e[0;0m"
		elif pgrep -a apt >/dev/null
			then echo -e "\e[1;31mEs läuft bereits ein APT-Prozess.\e[0;0m"
		else aptUpgrade
		fi
