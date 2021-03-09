
def Z-submap %{
    on-key %{z-handle %val{key} 0 true}
}

def -params 1 z-submap %{
    decl -hidden int zcount %arg{1}
    on-key %{z-handle %val{key} %opt{zcount} false}
}

def z-handle -params 3 %{
  eval %sh{
    repeat=$3
    z=""
    Z=""
    case "$1" in
      #H)            echo exec Gi  ;;
      h) Z="exec vh"; z="newsel h" ;;
      t) Z="exec vj"; z="exec vt"  ;;
      n) Z="exec vk"; z="exec ge"  ;;
      s) Z="exec vl"; z="newsel l" ;;

      c) echo exec vc ;;
      b) echo exec vb ;;
      N) echo exec Ge ;;

      6) echo exec gt ;;
      7) echo exec gc ;;
      8) echo exec gb ;;

      w) echo exec '<c-f>gc' ; repeat="true" ;;
      v) echo exec '<c-b>gc' ; repeat="true" ;;
      W) echo exec '<c-d>gc' ; repeat="true" ;;
      V) echo exec '<c-u>gc' ; repeat="true" ;;

      f) Z="exec <a-n>vc" ;;
      g) Z="exec nvc"
         if [ "$2" -eq 0 ]; then
           z="exec gg";
         else
           z="exec $kak_opt_zcount g";
         fi
         ;;
      G) if [ "$2" -eq 0 ]; then
           echo exec Gg;
         else
           echo "exec $kak_opt_zcount G";
         fi
         ;;
      #e) echo "exec ';Gl'" ;;
      #E) echo "exec 'Gl'" ;;
      #a) echo "exec ';Gh'" ;;
      #A) echo "exec 'Gh'" ;;
      k) echo exec '<A-K>' ;;
      o) echo exec '<A-a>' ;;
      i) echo exec '<A-i>' ;;
      q) echo exec ':q<ret>' ;;
      ']') echo exec ']' ;;
      '[') echo exec '[' ;;

      r) echo exec ': i3-new-right<ret>' ;;
      R) echo exec ': i3-new-down<ret>' ;;

      F) echo exec gf ;;
      u) echo exec 'g.' ;;
      '`') echo exec 'ga' ;;
      m) repeat="true" ;;
      *) # z="echo -- '$1' unused";
         repeat="false" ;;
      # d still unused
    esac
    if [[ "$repeat" == "true" ]]; then
      echo "$Z"
      echo 'echo -- -- Z --'
      echo on-key %{z-handle %val{key} 0 true}
    else
      echo "$z"
      echo echo
    fi
  }
}

map global normal z ': z-submap<space>%val{count}<ret>'
map global normal Z ': Z-submap<ret>'

def -params 1 new-client-here %{
  eval %sh{
    echo "new exec :buffer <space> $kak_buffile <ret> $kak_cursor_line g<ret>"
  }
}

