
# less intrusive c
map global normal c ': replace-if-all-single-char<ret>'

def -hidden replace-if-all-single-char %{ eval %sh{
python - $kak_selections_desc <<PY
import sys
for desc in sys.argv[1].split(':'):
    anchor, cursor = desc.split(',')
    if anchor != cursor:
        print("exec -with-hooks c")
        break
else:
    print("one-char-replace")
PY
}}

def -hidden one-char-replace %{
  hook window -group one-char-replace InsertChar .* %{
    exec <right><backspace>
    remove-hooks window one-char-replace
  }
  hook window -group one-char-replace ModeChange .*:insert:.* %{
    remove-hooks window one-char-replace
  }
  exec -with-hooks i
}

