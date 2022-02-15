_wh () {
  # Wenn das letzte Argument mit "-" beginnt, Parameter komplettieren
  if [[ ${COMP_WORDS[-1]} =~ ^-.* ]]; then
    COMPREPLY=($(compgen -W "--forecolor --backcolor -f -b --help -h" -- "${COMP_WORDS[-1]}"))
  fi

  # Wenn Vorletztes Argument -f,--foreground,-b oder --background, Farben kompletieren
  case ${COMP_WORDS[-2]} in
    -f | --forecolor | -b | --backcolor)
      COMPREPLY=($(compgen -W "black red green orange blue purple cyan lgray lightgray \
        dgray darkgray lred lightred lgreen lightgreen yellow lblue lightblue lpurple  \
        lightpurple lcyan lightcyan white nc nocolor none" -- "${COMP_WORDS[-1]}"))
    ;;
  esac

}
complete -F _wh wh
