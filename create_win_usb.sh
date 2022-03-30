#!/bin/bash
set -e
create_usb() {
  local DEVS=$(for dev in /sys/block/*;do
      if udevadm info --query=property --path=$dev|grep -q ^ID_BUS=usb;then
        sed -E "s#^.*/#/dev/#" <<< $dev
      fi
    done
  )
  local IFS=$'\n'
  local SEL
  local PKG

  if [ -z "$DEVS" ];then echo "Kein USB-Gerät gefunden. ";return 1;fi
  if ! SEL=$(whiptail --menu "USB-Gerät auswählen" 0 0 0 --ok-button Ok --cancel-button Abbruch \
    $(lsblk -ldno path,vendor,model $DEVS | awk '{print $1 "\n" $2 " " $3}') 3>&1 1>&2 2>&3);then
    return 1
  fi
  whiptail --yesno "ACHTUNG: Alle Daten auf '$SEL' werden gelöscht!\n\nMöchten Sie fortfahren?" 0 0
  unset IFS
  for dev in $(mount | awk "\$1 ~ \"^$SEL\" {print \$1}");do sudo umount "$(lsblk -lno mountpoint $dev)";done
  SIZE=$(($(lsblk -lbdno SIZE $SEL)/512-2044))

  if test $SIZE -le 12787712;then echo "Der Stick ist zu klein. ";return 1
  elif test $SIZE -le 20971520;then local P1=$(($SIZE-12582912))
  else local P1=8388608
  fi

  awk "BEGIN {printf \"$SEL wird formatiert:\n - P1: %6.2f GiB, Fat32\n - P2: %6.2f GiB, NTFS\n\n\", $P1/2097152, 6}"
  sudo sfdisk $SEL << EoF >/dev/null 2>&1
    ,$P1
    ,6G
EoF

  sudo mkfs.fat -F32 ${SEL}1 >/dev/null 2>&1
  sudo fatlabel ${SEL}1 "USB_BOOT" >/dev/null 2>&1
  sudo mkfs.ntfs -f ${SEL}2 >/dev/null 2>&1
  sudo ntfslabel ${SEL}2 "USB_WIN" >/dev/null 2>&1

  sudo mkdir -p /media/usb_{boot,win}
  sudo mount -o umask=000,dmask=000 ${SEL}1 /media/usb_boot
  sudo mount ${SEL}2 /media/usb_win

  PKG=$(dpkg --get-selections efibootmgr grub-efi-amd64-bin |awk '$2 != "install" {print $1}')
  if [ ! -z "$PKG" ];then sudo apt -y install $PKG;fi

  echo -n "Grub "
  sudo grub-install --removable --recheck --target=x86_64-efi --efi-directory=/media/usb_boot --boot-directory=/media/usb_boot/boot
  sudo grub-mkfont -s 24 -o /media/usb_boot/boot/grub/fonts/dejavu.pf2 /usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf
  echo
}

browse_file(){
  local TITLE=$1
  local SEARCH=$2
  local CUR=$PWD
  local ITEMS
  local SEL
  local IFS=$'\n'

  until [[ ${SEL,,} =~ ${SEARCH,,} ]];do
    ITEMS=$(ls -pAL1 --group-directories-first $CUR|grep -iP "/$|$SEARCH"|awk '{print $0 "\n" $0}')
    if [ "$CUR" != "/" ];then ITEMS=$(echo -e "..\n..\n$ITEMS");fi
    if ! SEL=$(whiptail --title "$TITLE" --menu "\nVerzeichnis: $CUR" 0 0 0 --noitem --ok-button Ok --cancel-button Abbruch $ITEMS 3>&1 1>&2 2>&3);then return 1;fi
    CUR=$(realpath "$CUR/$SEL")
  done
  echo $CUR
}

create_usb
SEL=$(browse_file "Windows-ISO auswählen" .*win.*\.iso$)
echo "'$SEL' wird entpackt"
7z x -bso0 -bsp1 -o/media/usb_win/ "$SEL"
echo

cat << EoF >> /media/usb_boot/boot/grub/grub.cfg
# Grundeinstellungen
set gfxmode=auto
set gfxpayload=keep
terminal_input console
terminal_output console
insmod ntfs
loadfont dejavu

# Menüeinträge
menuentry "Windows" {
  search -snl USB_WIN root
  chainloader /efi/boot/bootx64.efi
}
EoF

sync
sudo umount /media/usb_{boot,win}
sudo rm -R /media/usb_{boot,win}

echo "Der USB-Stick wurde erfolgreich erstellt. Sie können den PC jetzt neustarten. "
