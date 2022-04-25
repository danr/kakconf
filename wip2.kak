# https://discuss.kakoune.com/t/restoring-selections-after-accidental-clear/1366

# Save selections to the [b]ackup register.
rmhooks global backup-selections
hook -group backup-selections global NormalIdle .* %{
  reg b %reg{z}
  exec -draft '"zZ'
}

# Add a mapping to easily reach the command.
map -docstring 'Restore selections from the [b]ackup register' global user z '"bz'

