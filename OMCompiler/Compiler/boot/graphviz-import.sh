echo "digraph depends {" > depends.dot
for f in `grep ALL_SOURCES Makefile.sources | cut -d= -f2`; do
  f2=`echo $f | cut -d/ -f3 | cut -d. -f1`
  echo "  \"$f2\" [label=\"$f2\"];" >> depends.dot
  for i in `egrep "^ *(public|protected)? *import" "$f" | grep -o "import \+[A-Za-z0-9_]\+ *;" | cut -d" " -f2 | cut -d";" -f1`; do
    echo "  \"$f2\" -> \"$i\";" >> depends.dot
  done
  for i in `egrep "^ *(public|protected)? *import" "$f" | grep -o "import \+[A-Za-z0-9_]\+ *= *[A-Za-z0-9_]\+ *;" | cut -d= -f2 | cut -d";" -f1`; do
    echo "  \"$f2\" -> \"$i\";" >> depends.dot
  done
done
echo "}" >> depends.dot
gv2gml depends.dot > depends.gml
