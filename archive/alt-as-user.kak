
# Make alt- commands accessible as user commands
%sh{
python - <<PY
import string
for i in string.printable[:95]:
  if i != '\\\\':
    lhs = repr(i)
    rhs = repr('<A-'+i+'>') if i != '>' else '<a-lt>'
    print('map global user -- ' + lhs + ' ' + rhs)
PY
}

