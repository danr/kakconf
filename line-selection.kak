
def full-line-ifte -params 2 %{
  eval -no-hooks -itersel %{
    try %{
      # are we at the newline or on the char before?
      exec -draft <a-:> l <a-k> [\n] <ret>
      # is there only indentation to the left?
      exec -draft <a-:><a-\;> \; Gh <a-k> \A^\h*.\z <ret>
      # then execute second arg
      exec %arg{2}
    } catch %{
      # otherwise execute the first
      exec %arg{1}
    }
  }
}

def line-select %{ full-line-ifte giGl JGl }
def line-new-cursor %{
    full-line-ifte giGl '"vZjgiGl"v<a-z>a'
    try print-selection-info
}

