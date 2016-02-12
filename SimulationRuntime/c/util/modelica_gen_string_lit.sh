#!/bin/sh

if [ "$1" = "h" ] ; then
echo '#ifndef __META_MODELICA_STRING_LIT__H'
echo '#define __META_MODELICA_STRING_LIT__H'
echo 'extern void *mmc_emptystring;'
echo 'extern void *mmc_strings_len1[256];'
echo 'extern void *mmc_string_uninitialized;'
echo 'extern void *mmc_strings_boolString[2];'
echo '#endif'
exit
fi

echo '#include "meta/meta_modelica.h"'
HEX="0 1 2 3 4 5 6 7 8 9 A B C D E F"
echo 'static const MMC_DEFSTRINGLIT(OMC_STRINGLIT_0,0,"");'
echo 'void* mmc_emptystring = MMC_REFSTRINGLIT(OMC_STRINGLIT_0);'
for i in $HEX; do
for j in $HEX; do
  if [ $i$j != "00" ] ; then
    echo "static MMC_DEFSTRINGLIT(OMC_STRINGLIT_1_$i$j,1,\"\\x$i$j\");"
  fi
done
done

echo 'void* mmc_strings_len1[256] = {'
echo 'NULL,'
for i in $HEX; do
for j in $HEX; do
  if [ $i$j != "00" ] ; then
    echo "MMC_REFSTRINGLIT(OMC_STRINGLIT_1_$i$j),"
  fi
done
done
echo "};"
echo

echo 'static MMC_DEFSTRINGLIT(OMC_STRINGLIT_UNINITIALIZED,23,"$#*OMC_UNINITIALIZED*#$");'
echo 'void* mmc_string_uninitialized = MMC_REFSTRINGLIT(OMC_STRINGLIT_UNINITIALIZED);'

echo

echo "static const MMC_DEFSTRINGLIT(OMC_STRINGLIT_BOOLSTRING_0,5,\"false\");"
echo "static const MMC_DEFSTRINGLIT(OMC_STRINGLIT_BOOLSTRING_1,4,\"true\");"
echo "void* mmc_strings_boolString[2] = {"
echo "MMC_REFSTRINGLIT(OMC_STRINGLIT_BOOLSTRING_0),"
echo "MMC_REFSTRINGLIT(OMC_STRINGLIT_BOOLSTRING_1)"
echo "};"

exit
# The rest is not used because the gain is not known

for i in $HEX; do
for j in $HEX; do
for k in $HEX; do
for l in $HEX; do
  if [ $i$j != "00" ] && [ $k$l != "00" ] ; then
    echo "static const MMC_DEFSTRINGLIT(OMC_STRINGLIT_2_$i$j$k$l,2,\"\\\\x$i$j\\\\x$k$l\");"
  fi
done
done
done
done

echo 'const void* mmc_strings_len2[255][255] = {'

for i in $HEX; do
for j in $HEX; do
if [ $i$j != "00" ] ; then
  echo "{"
for k in $HEX; do
for l in $HEX; do
  if [ $k$l != "00" ] ; then
    echo "MMC_REFSTRINGLIT(OMC_STRINGLIT_2_$i$j$k$l),"
  fi
done
done
  echo "},"
fi
done
done

echo "};"
echo

# Hex 40 through 7F contain A-Z, a-z
HEX4="4 5 6 7"
for i in $HEX4; do
for j in $HEX; do
for k in $HEX4; do
for l in $HEX; do
for m in $HEX4; do
for n in $HEX; do
  echo "static const MMC_DEFSTRINGLIT(OMC_STRINGLIT_3_$i$j$k$l$m$n,3,\"\\\\x$i$j\\\\x$k$l\\\\x$m$n\");"
done
done
done
done
done
done

echo 'const void* mmc_strings_len3[64][64][64] = {'

for i in $HEX4; do
for j in $HEX; do
echo "{"
for k in $HEX4; do
for l in $HEX; do
echo "{"
for k in $HEX4; do
for l in $HEX; do
  echo "MMC_REFSTRINGLIT(OMC_STRINGLIT_3_$i$j$k$l$m$n),"
done
done
echo "},"
done
done
echo "},"
done
done

echo "};"

echo


