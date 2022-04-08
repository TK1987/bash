#!/bin/bash
set -e

# Programmordner in Home erstellen
if [ ! -d "$HOME/.local/bin" ];then
  mkdir -p $HOME/.local/bin
  echo "Ordner '$HOME/.local/bin' wurde erstellt. "
fi

# Sudo-Askpass-Skript erstellen
cat << -- > $HOME/.local/bin/askpass.sh && chmod +x $HOME/.local/bin/askpass.sh
#!/bin/bash
whiptail --passwordbox "[sudo] Passwort für \$USER: " 8 35 3>&1 1>&2 2>&3
--
echo "Sudo-Askpass-Skript wurde erstellt. "

# Sudo-Askpass-Skript in bashrc hinzufügen - sofern bereits vorhanden, eintrag ersetzen
if grep -iqP "^export +sudo_askpass" .bashrc;then
  sed -i -E "s#^(export SUDO_ASKPASS)=.*#\1=$HOME/.local/bin/askpass.sh#" $HOME/.bashrc
else
  echo -e "export SUDO_ASKPASS=/home/krichel/.local/bin/askpass.sh" >> $HOME/.bashrc
fi && . .bashrc
echo "Variable 'SUDO_ASKPASS' wurde in '$HOME/.bashrc' definiert."
echo -e "\nSie können ab sofort \e[93m'sudo -A'\e[0m nutzen, um die Passwortabfrage mit feedback zu erhalten. "
