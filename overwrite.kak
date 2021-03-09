
# overwrite a'la vim's R

def overwrite %{
  try %{
    hook window -group overwrite InsertChar .* %{exec <right><backspace>}
    map window insert <backspace> <left>
    hook window -group overwrite ModeChange pop:insert.* %{
      remove-hooks window overwrite
      unmap window insert <backspace> <left>
    }
    exec -with-hooks i
  }
}

