#!/bin/bash

install_dir="/opt/powershell"
VERBOSE=false

# Bei unerwarteten Fehlern abbrechen
set -e

verbose(){
  if [ "$VERBOSE" = "true" ];then
    case "$1" in
      -s) shift; success "$@";;
      -f) shift; fail "$@";;
      *) msg "$@";;
    esac
  fi
}

success(){ 1>&2 printf '%s \u2705\n' "$@" ;}

fail(){ 1>&2 printf '%s \u274c\n' "$@" ;}

info(){ 1>&2 printf 'INFO: %s\n' "$@" ;}

msg(){ 1>&2 printf '%s\n' "$@" ;}

get_package_suffix(){
  case `uname -m` in
    x86_64)  echo "linux-x64.tar.gz";;
    aarch64)  echo "linux-arm64.tar.gz";;
    armv7l)  echo "linux-arm32.tar.gz";;
    *)       1>&2 printf '\e[91;1m%s\e[0m\n' "Unbekannte Architektur."
             return 1;;
  esac
}

check_permissions(){
  if [ $EUID != 0 ];then
    1>&2 printf '\e[93;1m%s\e[0m\n' "Dieses Skript muss mit sudo gestartet werden."
    return 9
  fi
}

check_depends(){
  local packages=""
  verbose "Prüfe abhängige Pakete..."
  for PKG in `apt-cache pkgnames | grep -P "^(wget|jq|ca-certificates|libc\d|libgcc-s1|libgssapi-krb[\d-]+|libicu\d+|libssl[\d\w]+|libstdc\+\+\d|zlib1g)$"`;do
    if 1>/dev/null 2>&1 dpkg-query -W $PKG;then
      verbose -s " - $PKG"
    else
      verbose -f " - $PKG"
      packages+="$PKG "
    fi
  done

  if [ -n "$packages" ];then
    info "Nicht alle erforderlichen Pakete sind installiert: $packages" "Versuche abhängige Pakete zu installieren..."
    apt-get update -qq
    apt-get install -y $packages
  fi
  verbose -s "Abhängige Pakete sind installiert"
}

case "$1" in
  -v|--verbose) VERBOSE=true;;
esac

# Prüfe Berechtigungen
check_permissions
verbose -s "Sudo-Rechte sind vorhanden"

# Prüfe ob abhängige Pakete installiert sind
check_depends

# Installationsverzeichnis erstellen, falls nicht vorhanden.
[ -d "${install_dir}" ] && verbose -s "Installationsverzeichnis ${install_dir} existiert" || (mkdir -p "${install_dir}" && verbose -s "Installationsverzeichnis ${install_dir} wurde erstellt")

# Prüfe aktuellste Version
latest_source=`wget -qO- https://api.github.com/repos/powershell/powershell/releases/latest`
latest_version=`jq -r '.tag_name' <<<${latest_source}`
verbose "Aktuellste Version: ${latest_version#v}"

# Prüfe installierte Version (falls vorhanden)
if [ -x "${install_dir}/pwsh" ];then
  installed_version=`cut -d' ' -f2 < <("${install_dir}/pwsh" -v)`
  verbose "Installierte Version: ${installed_version}"
fi

# Prüfe ob die installierte Version der aktuellen entspricht
if [ "${latest_version}" = "v${installed_version}" ];then
  success "Die aktuellste Version $installed_version ist bereits installiert"
else
  temp_dir=`mktemp -d`
  verbose -s "Temporärer Ordner ${temp_dir} wurde erstellt"
  msg "Entpacke Version ${latest_version}..."
  jq --arg file `get_package_suffix` -r '.assets[].browser_download_url|select(.|endswith($file))' <<<$latest_source | xargs -r wget -qO- | tar -C "${temp_dir}" -xvz | xargs -d $'\n' -n1 1>&2 echo " -"
  chmod -R 755 "${temp_dir}"
  chmod +x "${temp_dir}/pwsh"
  rm -R "${install_dir}"
  mv "${temp_dir}" "${install_dir}"
  ln -sf /opt/powershell/pwsh /usr/bin/pwsh
  verbose -s "Verknüpfung /usr/bin/pwsh wurde erstellt"
  ln -sf /opt/powershell/pwsh /usr/bin/powershell
  verbose -s "Verknüpfung /usr/bin/powershell wurde erstellt"
  success "PowerShell ${latest_version#v} wurde erfolgreich installiert"
  info "Führen sie 'pwsh' oder 'powershell' aus, um es zu starten."
fi
