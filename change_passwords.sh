#!/usr/bin/sudo /bin/bash

if [ "${BASH_SOURCE[0]}" = "${0}" ];then EXIT=exit;else EXIT=return;fi
if [ "$EUID" != 0 ];then sudo "${BASH_SOURCE[0]}";$EXIT 0;fi

mainmenu () {
  local IFS=$'\n'
  local DEVS=($(lsblk -lno PATH,FSTYPE,SIZE,MOUNTPOINT | awk '$2 == "ext4" && $4 != "/" {printf "%-15s  %8s  %8s\n",$1,$2,$3}'))
  local CH=$(for (( i=0 ; i<${#DEVS[@]} ; i++ ));do echo -e "$i:\n${DEVS[$i]}";done)
  local SEL=$( whiptail --title "Root-System auswählen: " \
    --menu "\n     Gerät           Dateisystem   Größe" 0 0 0 \
     --ok-button Ok --cancel-button Beenden \
    $CH 3>&1 1>&2 2>&3
  )
  if [ -z "$SEL" ];then $EXIT 1;else echo ${DEVS[${SEL:0:1}]};fi
}

lsusr () {
  local IFS=$'\n'
  local USERS=$(cat $1/etc/group|awk -F: '$3 == 0 || ($3 >=1000 && $3 <=2000) {print $1 "\n" $1}')
  local SEL=$( whiptail --title "Passwort ändern für: " --menu "\nBenutzer auswählen: " 0 0 0 \
    --notags \
    --ok-button ok --cancel-button Abbruch \
    $USERS 3>&1 1>&2 2>&3
  )
  if [ -z "$SEL" ];then $EXIT 1;else echo $SEL;fi
}

readpw () {
  local PWD=$( whiptail --passwordbox "Neues Passwort für Benutzer $USR: " 8 0 --ok-button ok --cancel-button Abbruch 3>&1 1>&2 2>&3 )
  if [ -z "$PWD" ];then $EXIT 1;fi
  local RPW=$( whiptail --passwordbox "Passwort erneut eingeben: " 8 0 --ok-button ok --cancel-button Abbruch 3>&1 1>&2 2>&3 )

  if [ "$PWD" = "$RPW" ]
    then local KEY=$(echo $PWD | mkpasswd -s -m sha-512)
      sed -iE "s#^$1:[^:]*#$1:$KEY#" $2/etc/shadow
    else whiptail --msgbox "Passwörter stimmen nicht überein! " 0 0
      readpw $1 $2
  fi
}

ROOT=($(mainmenu))
if [[ $? == 1 || -z "$ROOT" ]];then $EXIT 1;fi

MP=$(lsblk $ROOT -lno MOUNTPOINT)

USR=$(lsusr $MP)
if [[ $? == 1 || -z "$USR" ]];then $EXIT 1;fi

readpw $USR $MP
