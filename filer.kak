eval %sh{
    cd "$(dirname "$kak_source")"
    python filer.py --source
}
