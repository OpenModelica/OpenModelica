if ! test -f "$1"; then
  echo "File \'$1\' does not exist"
fi
if ! test -f "$2"; then
  echo "File \'$2\' does not exist"
fi
BUILD="(<tr><td bgcolor=.#ff0000)|(tr.*/td.*/td.*td bgcolor=..FF0000.*/td.*/td.*/td.*/td.*/td)"
SIM="(<tr><td bgcolor=.#ff0000)|(tr.*/td.*td bgcolor=..FF0000.*/td.*/td.*/td.*/td)"
SEARCH=">[A-Z][A-Za-z0-9._]*(<| [(])"
REV1=`grep -o "[(]r[0-9]*" "$1" | tr -d "("`
REV2=`grep -o "[(]r[0-9]*" "$2" | tr -d "("`
egrep "$BUILD" $1 | egrep -o "$SEARCH" | tr -d "<> (" > "$1.build"
egrep "$BUILD" $2 | egrep -o "$SEARCH" | tr -d "<> (" > "$2.build"
echo "Build diff (failures between $REV1 and $REV2 *plus is bad*)"
diff -u "$1.build" "$2.build" | grep ^[+-]

egrep "$SIM" "$1" | egrep -o "$SEARCH" | tr -d "<> (" > "$1.sim"
egrep "$SIM" "$2" | egrep -o "$SEARCH" | tr -d "<> (" > "$2.sim"
echo "Sim diff (failures between $REV1 and $REV2 - *plus is bad*)"
diff -u "$1.sim" "$2.sim" | grep "^[+-][A-Za-z0-9._]"
rm -f "$1.build" "$2.build" "$1.sim" "$2.sim"

# xpath -e "html/body/table/tr/td[2][@bgcolor = '#FF0000']/../td[1]/text()" BuildModelRecursive.html
