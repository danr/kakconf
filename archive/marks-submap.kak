
# marks: jump to and save sels
def marks -params 0..1 %{
  info -title "marks%arg{1}" %{(g)et   z
(s)et   Z
(a)dd   <a-Z>
(u)nion <a-z>}
  on-key %{eval %sh{
    key=""
    case "$kak_key" in
      g) key=z ;;
      s) key=Z ;;
      a) key='<a-Z>' ;;
      u) key='<a-z>' ;;
      w) key=':easy-motion-word<ret>' ;;
      l) key=':easy-motion-line<ret>' ;;
      [a-zA-Z]) echo marks '%{"'"$kak_key"'}' ;;
      *) echo echo marks: unbound "$kak_key" ;;
    esac
    if [[ "$key" ]]; then
        echo exec -save-regs "''" '%{'"$1""$key"'}'
    fi
  }}
}

