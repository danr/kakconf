
def select-all-focus-closest %{
    exec '%s<ret>' :focus-closest-to-line <space> %val{cursor_line} <ret>
    print-selection-info
}

def -params 1 focus-closest-to-line %{ eval %sh{
python - $1 $kak_selection_desc $kak_selections_desc <<PY
import sys
goto, current, *all = sys.argv[1:]
def key(t):
    desc = t[1]
    return abs(int(goto) - int(desc.split('.')[0]))
best_index, _ = min(enumerate(all), key=key)
current_index = all.index(current)
rots = best_index - current_index
if rots < 0: rots += len(all)
if rots != 0:
    print("exec {})".format(rots))
PY
}}

def print-selection-info nop
# %{ echo %sh{
#     i=1
#     j=0
#     for sel in ${kak_selections_desc[@]}; do
#         j=$(($j+1))
#         if [[ "$sel" < "$kak_selection_desc" ]]; then
#             i=$(($i+1))
#         fi
#     done
#     echo "selection $i/$j";
# }}

# hook -group kakrc global NormalKey .*([()'"nNCzZ]|<a-s>).* print-selection-info
hook -group kakrc global NormalKey [sS] %{
    try %{remove-hooks global once}
    hook global -group once ModeChange .*:normal:.* %{
        print-selection-info
        try %{remove-hooks global once}
    }
}

# hook global NormalKey .*[/?nN*].* highlight-search

# def highlight-search %{
#   noh
#   try %{
#     addhl window/ dynregex '%reg{/}' 0:Search 1:+u 2:+u
#   }
# }

# def noh %{
#   rmhl window/dynregex_%reg{<slash>}_0:Search_1:+u_2:+u
# }

