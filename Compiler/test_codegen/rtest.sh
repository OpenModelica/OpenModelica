#!/sw/gnu/bin/bash

function do_one() 
{
    
    if make -f Makefile.single TARGET=${mo/%.mo/} clean all > /dev/null 2> /dev/null;
    then echo OK;
    else echo failed;
    fi
    
    
}

points='....................................................... '

for mo in *.mo; do {
    echo -n ${mo} ${points:${#mo}} ' '
    do_one
    

} done
