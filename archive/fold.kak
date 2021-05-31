declare-option -hidden range-specs fold_regions 0
add-highlighter global/fold-regions replace-ranges fold_regions

# range-specs option format:
#
# - a timestamp (like %val{timestamp})
# - zero or more "a.b,c.d|string", where:
#     - a is the start line
#     - b is the start byte in the start line
#     - c is the end line
#     - d is the end byte in the end line
#     - string is a markup string of replacement text

# mark register format:
#
# - <buffer name>@<timestamp>@<main sel index>
# - zero or more "a.b,c.d"
#

map global normal q z
map global normal Q Z
map global normal <a-q> <a-z>a
map global normal <a-Q> <a-Z>a

rmhooks global fold
hook -group fold global RegisterModified \^ %{
    eval %sh{
        eval set -- "$kak_quoted_reg_caret"
        name_and_timestamp=${1%@*}
        name=${name_and_timestamp%@*}
        timestamp=${name_and_timestamp##*@}
        shift

        echo "echo -debug running in file $kak_buffile"

        if [ x"$kak_buffile" != x"$name" ]; then
            # The register value doesn't apply to this file,
            # ignore the update.
            exit
        fi

        echo "set-option buffer fold_regions $timestamp"
        for span; do
            echo "set-option -add buffer fold_regions '$span|..'"
        done
    }
}

